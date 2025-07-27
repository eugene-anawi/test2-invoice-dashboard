defmodule Test2.Streaming.Supervisor do
  @moduledoc """
  Supervisor for the invoice streaming system.
  
  Manages the OTP processes responsible for:
  - Invoice generation at 5/second
  - Display buffering at 2/second  
  - Statistics aggregation
  - Real-time broadcasting
  """
  
  use Supervisor
  
  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end
  
  @impl true
  def init(_init_arg) do
    children = [
      # Main coordinator - manages start/stop state
      {Test2.Streaming.Coordinator, []},
      
      # Invoice producer - generates invoices at 5/second
      {Test2.Streaming.Producer, []},
      
      # Display buffer - rate limits to 2/second for UI
      {Test2.Streaming.Buffer, []},
      
      # Statistics aggregator - real-time stats calculation
      {Test2.Streaming.StatsAggregator, []},
      
      # Broadcaster - manages Phoenix PubSub events
      {Test2.Streaming.Broadcaster, []}
    ]
    
    # Use :one_for_one strategy - if one process crashes, only restart that one
    # This ensures other parts of the streaming system continue working
    Supervisor.init(children, strategy: :one_for_one)
  end
  
  @doc """
  Gets the status of all streaming processes
  """
  def get_system_status do
    %{
      coordinator: process_status(Test2.Streaming.Coordinator),
      producer: process_status(Test2.Streaming.Producer),
      buffer: process_status(Test2.Streaming.Buffer),
      stats_aggregator: process_status(Test2.Streaming.StatsAggregator),
      broadcaster: process_status(Test2.Streaming.Broadcaster)
    }
  end
  
  defp process_status(module) do
    case GenServer.whereis(module) do
      nil -> :not_running
      pid when is_pid(pid) -> :running
    end
  end
end