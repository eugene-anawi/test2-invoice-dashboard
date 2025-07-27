defmodule Test2.Streaming.Coordinator do
  @moduledoc """
  Main coordinator GenServer for the invoice streaming system.
  
  Manages the overall state (started/stopped) and coordinates
  between the producer, buffer, and other components.
  
  Responsibilities:
  - Track running state (started/stopped)
  - Handle start/stop commands from UI
  - Coordinate graceful shutdown with backlog processing
  - Monitor system health
  """
  
  use GenServer
  require Logger
  
  alias Test2.Streaming.{Producer, Buffer, StatsAggregator, Broadcaster}
  
  # Client API
  
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end
  
  @doc """
  Starts the invoice generation process
  """
  def start_generation do
    GenServer.call(__MODULE__, :start_generation)
  end
  
  @doc """
  Stops the invoice generation process
  Note: Display buffer will continue processing backlog
  """
  def stop_generation do
    GenServer.call(__MODULE__, :stop_generation)
  end
  
  @doc """
  Gets the current system status
  """
  def get_status do
    GenServer.call(__MODULE__, :get_status)
  end
  
  @doc """
  Forces a complete system reset (for testing)
  """
  def reset_system do
    GenServer.call(__MODULE__, :reset_system)
  end
  
  # Server callbacks
  
  @impl true
  def init([]) do
    state = %{
      status: :stopped,
      started_at: nil,
      total_generated: 0,
      total_displayed: 0,
      last_activity: DateTime.utc_now()
    }
    
    Logger.info("Streaming Coordinator started")
    {:ok, state}
  end
  
  @impl true
  def handle_call(:start_generation, _from, state) do
    case state.status do
      :stopped ->
        # Start the producer
        :ok = Producer.start_generation()
        
        new_state = %{state | 
          status: :running,
          started_at: DateTime.utc_now(),
          last_activity: DateTime.utc_now()
        }
        
        # Broadcast status change via Broadcaster
        Broadcaster.broadcast_system_status(:started, new_state)
        
        Logger.info("Invoice generation started")
        {:reply, {:ok, :started}, new_state}
        
      :running ->
        {:reply, {:error, :already_running}, state}
        
      :stopping ->
        {:reply, {:error, :currently_stopping}, state}
    end
  end
  
  @impl true
  def handle_call(:stop_generation, _from, state) do
    case state.status do
      :running ->
        # Stop the producer (buffer will continue processing backlog)
        :ok = Producer.stop_generation()
        
        new_state = %{state | 
          status: :stopping,
          last_activity: DateTime.utc_now()
        }
        
        # The system will transition to :stopped when buffer is empty
        # This is handled by the buffer process notifying us
        
        # Broadcast status change via Broadcaster
        Broadcaster.broadcast_system_status(:stopping, new_state)
        
        Logger.info("Invoice generation stopped, processing backlog...")
        {:reply, {:ok, :stopping}, new_state}
        
      :stopped ->
        {:reply, {:error, :already_stopped}, state}
        
      :stopping ->
        {:reply, {:error, :already_stopping}, state}
    end
  end
  
  @impl true
  def handle_call(:get_status, _from, state) do
    status_info = Map.merge(state, %{
      buffer_size: Buffer.get_buffer_size(),
      generation_rate: Producer.get_generation_rate(),
      display_rate: Buffer.get_display_rate()
    })
    
    {:reply, status_info, state}
  end
  
  @impl true
  def handle_call(:reset_system, _from, _state) do
    # Reset all components
    Producer.reset()
    Buffer.reset()
    StatsAggregator.reset()
    
    new_state = %{
      status: :stopped,
      started_at: nil,
      total_generated: 0,
      total_displayed: 0,
      last_activity: DateTime.utc_now()
    }
    
    # Broadcast reset via Broadcaster
    Broadcaster.broadcast_system_status(:reset, new_state)
    
    Logger.info("System reset completed")
    {:reply, :ok, new_state}
  end
  
  @impl true
  def handle_info({:invoice_generated, _invoice}, state) do
    new_state = %{state | 
      total_generated: state.total_generated + 1,
      last_activity: DateTime.utc_now()
    }
    {:noreply, new_state}
  end
  
  @impl true
  def handle_info({:invoice_displayed, _invoice}, state) do
    new_state = %{state | 
      total_displayed: state.total_displayed + 1,
      last_activity: DateTime.utc_now()
    }
    {:noreply, new_state}
  end
  
  @impl true
  def handle_info({:buffer_empty}, state) do
    # If we're stopping and buffer is empty, transition to stopped
    case state.status do
      :stopping ->
        new_state = %{state | status: :stopped}
        
        Broadcaster.broadcast_system_status(:stopped, new_state)
        
        Logger.info("System fully stopped - backlog processed")
        {:noreply, new_state}
        
      _ ->
        {:noreply, state}
    end
  end
  
  @impl true
  def handle_info(msg, state) do
    Logger.debug("Coordinator received unexpected message: #{inspect(msg)}")
    {:noreply, state}
  end
end