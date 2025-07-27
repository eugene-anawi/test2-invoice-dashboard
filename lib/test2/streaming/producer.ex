defmodule Test2.Streaming.Producer do
  @moduledoc """
  Invoice Producer GenServer - generates invoices at 5 per second.
  
  Responsibilities:
  - Generate random invoices at specified rate (5/second)
  - Save invoices to PostgreSQL database
  - Send invoices to buffer for display rate limiting
  - Track generation statistics
  - Handle start/stop commands gracefully
  """
  
  use GenServer
  require Logger
  
  alias Test2.Invoices.{Invoice, Generator}
  alias Test2.Streaming.{Buffer, StatsAggregator}
  
  @generation_rate_ms 200  # 5 per second = 200ms intervals
  @generation_duration_ms 5 * 60 * 1000  # 5 minutes in milliseconds
  
  # Client API
  
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end
  
  @doc """
  Starts invoice generation at 5/second for 5 minutes
  """
  def start_generation do
    GenServer.call(__MODULE__, :start_generation)
  end
  
  @doc """
  Stops invoice generation immediately
  """
  def stop_generation do
    GenServer.call(__MODULE__, :stop_generation)
  end
  
  @doc """
  Gets current generation rate and statistics
  """
  def get_generation_rate do
    GenServer.call(__MODULE__, :get_stats)
  end
  
  @doc """
  Resets the producer state
  """
  def reset do
    GenServer.call(__MODULE__, :reset)
  end
  
  # Server callbacks
  
  @impl true
  def init([]) do
    state = %{
      running: false,
      timer_ref: nil,
      generated_count: 0,
      start_time: nil,
      end_time: nil,
      target_count: 5 * 60 * 5,  # 5/second * 60 seconds * 5 minutes
      last_generation: nil
    }
    
    Logger.info("Invoice Producer started")
    {:ok, state}
  end
  
  @impl true
  def handle_call(:start_generation, _from, state) do
    case state.running do
      false ->
        # Calculate end time (5 minutes from now)
        start_time = DateTime.utc_now()
        end_time = DateTime.add(start_time, @generation_duration_ms, :millisecond)
        
        # Start the generation timer
        timer_ref = schedule_generation()
        
        new_state = %{state |
          running: true,
          timer_ref: timer_ref,
          start_time: start_time,
          end_time: end_time,
          generated_count: 0
        }
        
        Logger.info("Starting invoice generation for 5 minutes (#{new_state.target_count} invoices expected)")
        {:reply, :ok, new_state}
        
      true ->
        {:reply, {:error, :already_running}, state}
    end
  end
  
  @impl true
  def handle_call(:stop_generation, _from, state) do
    case state.timer_ref do
      nil -> 
        {:reply, :ok, %{state | running: false}}
      timer_ref ->
        Process.cancel_timer(timer_ref)
        Logger.info("Invoice generation stopped manually after #{state.generated_count} invoices")
        {:reply, :ok, %{state | running: false, timer_ref: nil}}
    end
  end
  
  @impl true
  def handle_call(:get_stats, _from, state) do
    stats = %{
      running: state.running,
      generated_count: state.generated_count,
      target_count: state.target_count,
      start_time: state.start_time,
      end_time: state.end_time,
      rate_per_second: if(state.running, do: 5, else: 0),
      last_generation: state.last_generation
    }
    
    {:reply, stats, state}
  end
  
  @impl true
  def handle_call(:reset, _from, state) do
    # Cancel any running timer
    if state.timer_ref do
      Process.cancel_timer(state.timer_ref)
    end
    
    new_state = %{
      running: false,
      timer_ref: nil,
      generated_count: 0,
      start_time: nil,
      end_time: nil,
      target_count: 5 * 60 * 5,
      last_generation: nil
    }
    
    {:reply, :ok, new_state}
  end
  
  @impl true
  def handle_info(:generate_invoice, state) do
    # Check if we should still be generating
    now = DateTime.utc_now()
    should_continue = state.running and 
                     (state.end_time == nil or DateTime.compare(now, state.end_time) == :lt) and
                     state.generated_count < state.target_count
    
    if should_continue do
      # Generate and save invoice
      case Generator.generate_random_invoice() do
        {:ok, invoice} ->
          # Send to buffer for display rate limiting
          Buffer.add_invoice(invoice)
          
          # Send to stats aggregator
          StatsAggregator.invoice_generated(invoice)
          
          # Notify coordinator
          send(Test2.Streaming.Coordinator, {:invoice_generated, invoice})
          
          # Schedule next generation
          timer_ref = schedule_generation()
          
          new_state = %{state |
            generated_count: state.generated_count + 1,
            timer_ref: timer_ref,
            last_generation: now
          }
          
          Logger.debug("Generated invoice #{invoice.invoice_number} (#{new_state.generated_count}/#{state.target_count})")
          {:noreply, new_state}
          
        {:error, changeset} ->
          Logger.error("Failed to generate invoice: #{inspect(changeset.errors)}")
          
          # Continue generating despite error
          timer_ref = schedule_generation()
          {:noreply, %{state | timer_ref: timer_ref}}
      end
    else
      # Generation period ended
      Logger.info("Invoice generation completed. Generated #{state.generated_count} invoices")
      
      new_state = %{state | 
        running: false, 
        timer_ref: nil
      }
      
      {:noreply, new_state}
    end
  end
  
  @impl true
  def handle_info({:DOWN, _ref, :process, _pid, _reason}, state) do
    # Handle monitored process termination if needed
    {:noreply, state}
  end
  
  @impl true
  def handle_info(msg, state) do
    Logger.debug("Producer received unexpected message: #{inspect(msg)}")
    {:noreply, state}
  end
  
  # Private functions
  
  defp schedule_generation do
    Process.send_after(self(), :generate_invoice, @generation_rate_ms)
  end
end