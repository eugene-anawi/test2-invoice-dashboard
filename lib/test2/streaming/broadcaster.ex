defmodule Test2.Streaming.Broadcaster do
  @moduledoc """
  Broadcaster GenServer - manages Phoenix PubSub events for real-time updates.
  
  Responsibilities:
  - Broadcast invoice displays to LiveView components
  - Broadcast statistics updates to dashboard cards
  - Broadcast system status changes
  - Manage different PubSub topics for different UI components
  - Handle broadcast failures gracefully
  """
  
  use GenServer
  require Logger
  
  # PubSub topics
  @invoice_topic "invoices"
  @stats_topic "stats"
  @system_topic "system_status"
  
  # Client API
  
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end
  
  @doc """
  Broadcasts an invoice for display in the grid
  """
  def broadcast_invoice_display(invoice) do
    GenServer.cast(__MODULE__, {:broadcast_invoice, invoice})
  end
  
  @doc """
  Broadcasts updated statistics to dashboard cards
  """
  def broadcast_stats_update(stats) do
    GenServer.cast(__MODULE__, {:broadcast_stats, stats})
  end
  
  @doc """
  Broadcasts system status changes
  """
  def broadcast_system_status(status, system_state) do
    GenServer.cast(__MODULE__, {:broadcast_status, status, system_state})
  end
  
  @doc """
  Gets broadcasting statistics
  """
  def get_broadcast_stats do
    GenServer.call(__MODULE__, :get_stats)
  end
  
  @doc """
  Resets broadcasting statistics
  """
  def reset do
    GenServer.call(__MODULE__, :reset)
  end
  
  # Server callbacks
  
  @impl true
  def init([]) do
    state = %{
      invoice_broadcasts: 0,
      stats_broadcasts: 0,
      status_broadcasts: 0,
      last_invoice_broadcast: nil,
      last_stats_broadcast: nil,
      last_status_broadcast: nil,
      broadcast_errors: 0
    }
    
    Logger.info("Broadcaster started")
    {:ok, state}
  end
  
  @impl true
  def handle_cast({:broadcast_invoice, invoice}, state) do
    try do
      # Broadcast to invoice grid topic
      Phoenix.PubSub.broadcast(Test2.PubSub, @invoice_topic, {:new_invoice, invoice})
      
      new_state = %{state |
        invoice_broadcasts: state.invoice_broadcasts + 1,
        last_invoice_broadcast: DateTime.utc_now()
      }
      
      Logger.debug("Broadcasted invoice: #{invoice.invoice_number}")
      {:noreply, new_state}
      
    rescue
      error ->
        Logger.error("Failed to broadcast invoice: #{inspect(error)}")
        {:noreply, %{state | broadcast_errors: state.broadcast_errors + 1}}
    end
  end
  
  @impl true
  def handle_cast({:broadcast_stats, stats}, state) do
    try do
      # Broadcast to statistics dashboard topic
      Phoenix.PubSub.broadcast(Test2.PubSub, @stats_topic, {:stats_update, stats})
      
      new_state = %{state |
        stats_broadcasts: state.stats_broadcasts + 1,
        last_stats_broadcast: DateTime.utc_now()
      }
      
      Logger.debug("Broadcasted stats update: #{stats.count} invoices, $#{Float.round(stats.total_amount, 2)}")
      {:noreply, new_state}
      
    rescue
      error ->
        Logger.error("Failed to broadcast stats: #{inspect(error)}")
        {:noreply, %{state | broadcast_errors: state.broadcast_errors + 1}}
    end
  end
  
  @impl true
  def handle_cast({:broadcast_status, status, system_state}, state) do
    try do
      # Broadcast to system status topic with correct format for LiveView
      Phoenix.PubSub.broadcast(Test2.PubSub, @system_topic, {:status_change, status, system_state})
      
      new_state = %{state |
        status_broadcasts: state.status_broadcasts + 1,
        last_status_broadcast: DateTime.utc_now()
      }
      
      Logger.debug("Broadcasted status change: #{status} with state: #{inspect(system_state)}")
      {:noreply, new_state}
      
    rescue
      error ->
        Logger.error("Failed to broadcast status: #{inspect(error)}")
        {:noreply, %{state | broadcast_errors: state.broadcast_errors + 1}}
    end
  end
  
  @impl true
  def handle_call(:get_stats, _from, state) do
    broadcast_stats = %{
      invoice_broadcasts: state.invoice_broadcasts,
      stats_broadcasts: state.stats_broadcasts,
      status_broadcasts: state.status_broadcasts,
      last_invoice_broadcast: state.last_invoice_broadcast,
      last_stats_broadcast: state.last_stats_broadcast,
      last_status_broadcast: state.last_status_broadcast,
      broadcast_errors: state.broadcast_errors,
      total_broadcasts: state.invoice_broadcasts + state.stats_broadcasts + state.status_broadcasts
    }
    
    {:reply, broadcast_stats, state}
  end
  
  @impl true
  def handle_call(:reset, _from, _state) do
    new_state = %{
      invoice_broadcasts: 0,
      stats_broadcasts: 0,
      status_broadcasts: 0,
      last_invoice_broadcast: nil,
      last_stats_broadcast: nil,
      last_status_broadcast: nil,
      broadcast_errors: 0
    }
    
    {:reply, :ok, new_state}
  end
  
  @impl true
  def handle_info(msg, state) do
    Logger.debug("Broadcaster received unexpected message: #{inspect(msg)}")
    {:noreply, state}
  end
  
  # Helper functions for easy access to topics
  
  @doc """
  Returns the invoice display topic name
  """
  def invoice_topic, do: @invoice_topic
  
  @doc """
  Returns the statistics topic name
  """  
  def stats_topic, do: @stats_topic
  
  @doc """
  Returns the system status topic name
  """
  def system_topic, do: @system_topic
end