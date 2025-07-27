defmodule Test2.Streaming.Buffer do
  @moduledoc """
  Display Buffer GenServer - rate limits invoice display to 2 per second.
  
  Responsibilities:
  - Receive invoices from Producer at 5/second
  - Buffer invoices in a queue
  - Release invoices to UI at 2/second for readable display
  - Handle backlog processing when generation stops
  - Notify coordinator when buffer is empty
  """
  
  use GenServer
  require Logger
  
  alias Test2.Streaming.Broadcaster
  
  @display_rate_ms 500  # 2 per second = 500ms intervals
  
  # Client API
  
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end
  
  @doc """
  Adds an invoice to the display buffer
  """
  def add_invoice(invoice) do
    GenServer.cast(__MODULE__, {:add_invoice, invoice})
  end
  
  @doc """
  Gets the current buffer size
  """
  def get_buffer_size do
    GenServer.call(__MODULE__, :get_buffer_size)
  end
  
  @doc """
  Gets display rate and statistics
  """
  def get_display_rate do
    GenServer.call(__MODULE__, :get_stats)
  end
  
  @doc """
  Resets the buffer state
  """
  def reset do
    GenServer.call(__MODULE__, :reset)
  end
  
  @doc """
  Forces immediate display of all buffered invoices (for testing)
  """
  def flush_buffer do
    GenServer.call(__MODULE__, :flush_buffer)
  end
  
  # Server callbacks
  
  @impl true
  def init([]) do
    state = %{
      buffer: :queue.new(),
      buffer_size: 0,
      displaying: false,
      display_timer_ref: nil,
      displayed_count: 0,
      last_display: nil,
      max_buffer_size: 0  # Track peak buffer size
    }
    
    # Start the display timer immediately
    timer_ref = schedule_display()
    
    Logger.info("Display Buffer started")
    {:ok, %{state | display_timer_ref: timer_ref, displaying: true}}
  end
  
  @impl true
  def handle_cast({:add_invoice, invoice}, state) do
    # Add invoice to buffer queue
    new_buffer = :queue.in(invoice, state.buffer)
    new_size = state.buffer_size + 1
    
    new_state = %{state |
      buffer: new_buffer,
      buffer_size: new_size,
      max_buffer_size: max(state.max_buffer_size, new_size)
    }
    
    Logger.debug("Invoice added to buffer. Buffer size: #{new_size}")
    {:noreply, new_state}
  end
  
  @impl true
  def handle_call(:get_buffer_size, _from, state) do
    {:reply, state.buffer_size, state}
  end
  
  @impl true
  def handle_call(:get_stats, _from, state) do
    stats = %{
      buffer_size: state.buffer_size,
      max_buffer_size: state.max_buffer_size,
      displayed_count: state.displayed_count,
      displaying: state.displaying,
      rate_per_second: if(state.displaying, do: 2, else: 0),
      last_display: state.last_display
    }
    
    {:reply, stats, state}
  end
  
  @impl true
  def handle_call(:reset, _from, state) do
    # Cancel display timer
    if state.display_timer_ref do
      Process.cancel_timer(state.display_timer_ref)
    end
    
    # Start fresh with new timer
    timer_ref = schedule_display()
    
    new_state = %{
      buffer: :queue.new(),
      buffer_size: 0,
      displaying: true,
      display_timer_ref: timer_ref,
      displayed_count: 0,
      last_display: nil,
      max_buffer_size: 0
    }
    
    {:reply, :ok, new_state}
  end
  
  @impl true
  def handle_call(:flush_buffer, _from, state) do
    # Display all buffered invoices immediately
    invoices = :queue.to_list(state.buffer)
    
    Enum.each(invoices, fn invoice ->
      display_invoice(invoice)
    end)
    
    new_state = %{state |
      buffer: :queue.new(),
      buffer_size: 0,
      displayed_count: state.displayed_count + length(invoices)
    }
    
    {:reply, {:ok, length(invoices)}, new_state}
  end
  
  @impl true
  def handle_info(:display_next, state) do
    case :queue.out(state.buffer) do
      {{:value, invoice}, new_buffer} ->
        # Display the invoice
        display_invoice(invoice)
        
        # Notify coordinator about display
        send(Test2.Streaming.Coordinator, {:invoice_displayed, invoice})
        
        new_state = %{state |
          buffer: new_buffer,
          buffer_size: state.buffer_size - 1,
          displayed_count: state.displayed_count + 1,
          last_display: DateTime.utc_now()
        }
        
        Logger.debug("Displayed invoice #{invoice.invoice_number}. Buffer size: #{new_state.buffer_size}")
        
        # Schedule next display
        timer_ref = schedule_display()
        {:noreply, %{new_state | display_timer_ref: timer_ref}}
        
      {:empty, _} ->
        # Buffer is empty
        if state.buffer_size > 0 do
          Logger.warn("Buffer reported empty but size was #{state.buffer_size}")
        end
        
        # Notify coordinator that buffer is empty
        send(Test2.Streaming.Coordinator, {:buffer_empty})
        
        # Continue scheduling to check for new invoices
        timer_ref = schedule_display()
        {:noreply, %{state | display_timer_ref: timer_ref, buffer_size: 0}}
    end
  end
  
  @impl true
  def handle_info(msg, state) do
    Logger.debug("Buffer received unexpected message: #{inspect(msg)}")
    {:noreply, state}
  end
  
  # Private functions
  
  defp schedule_display do
    Process.send_after(self(), :display_next, @display_rate_ms)
  end
  
  defp display_invoice(invoice) do
    # Broadcast to LiveView for real-time display
    Broadcaster.broadcast_invoice_display(invoice)
    
    Logger.debug("Broadcasting invoice for display: #{invoice.invoice_number}")
  end
end