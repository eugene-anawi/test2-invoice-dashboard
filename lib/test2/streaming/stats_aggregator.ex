defmodule Test2.Streaming.StatsAggregator do
  @moduledoc """
  Statistics Aggregator GenServer - maintains real-time invoice statistics.
  
  Responsibilities:
  - Receive invoice creation events
  - Update statistics incrementally (more efficient than DB queries)
  - Cache statistics in Redis for performance
  - Broadcast statistics updates to LiveView
  - Handle statistics resets and synchronization
  """
  
  use GenServer
  require Logger
  
  alias Test2.Invoices.Stats
  alias Test2.Streaming.Broadcaster
  alias Test2.Cache.StatsCache
  
  # Client API
  
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end
  
  @doc """
  Notifies the aggregator that an invoice was generated
  """
  def invoice_generated(invoice) do
    GenServer.cast(__MODULE__, {:invoice_generated, invoice})
  end
  
  @doc """
  Gets current statistics
  """
  def get_current_stats do
    GenServer.call(__MODULE__, :get_stats)
  end
  
  @doc """
  Forces a recalculation of statistics from the database
  """
  def recalculate_stats do
    GenServer.call(__MODULE__, :recalculate_stats)
  end
  
  @doc """
  Resets all statistics
  """
  def reset do
    GenServer.call(__MODULE__, :reset)
  end
  
  # Server callbacks
  
  @impl true
  def init([]) do
    # Initialize with current stats from database
    initial_stats = Stats.calculate_stats_from_db()
    
    state = %{
      current_stats: initial_stats,
      last_update: DateTime.utc_now(),
      update_count: 0
    }
    
    Logger.info("Stats Aggregator started with initial stats: #{inspect(initial_stats)}")
    {:ok, state}
  end
  
  @impl true
  def handle_cast({:invoice_generated, invoice}, state) do
    # Update statistics incrementally
    new_stats = update_stats_for_invoice(state.current_stats, invoice)
    
    # Cache the updated stats
    StatsCache.set_stats(new_stats)
    
    # Broadcast the updated stats to LiveView
    Broadcaster.broadcast_stats_update(new_stats)
    
    new_state = %{state |
      current_stats: new_stats,
      last_update: DateTime.utc_now(),
      update_count: state.update_count + 1
    }
    
    Logger.debug("Stats updated: #{new_stats.count} invoices, $#{Float.round(new_stats.total_amount, 2)} total")
    {:noreply, new_state}
  end
  
  @impl true
  def handle_call(:get_stats, _from, state) do
    {:reply, state.current_stats, state}
  end
  
  @impl true
  def handle_call(:recalculate_stats, _from, state) do
    # Recalculate from database (useful for synchronization)
    fresh_stats = Stats.calculate_stats_from_db()
    
    # Update cache
    StatsCache.set_stats(fresh_stats)
    
    # Broadcast update
    Broadcaster.broadcast_stats_update(fresh_stats)
    
    new_state = %{state |
      current_stats: fresh_stats,
      last_update: DateTime.utc_now()
    }
    
    Logger.info("Stats recalculated from database: #{inspect(fresh_stats)}")
    {:reply, fresh_stats, new_state}
  end
  
  @impl true
  def handle_call(:reset, _from, _state) do
    # Reset to zero stats
    reset_stats = %{
      count: 0,
      total_amount: 0.0,
      vat_total: 0.0,
      subtotal: 0.0,
      average_amount: 0.0
    }
    
    # Clear cache
    StatsCache.clear_stats()
    
    # Broadcast reset
    Broadcaster.broadcast_stats_update(reset_stats)
    
    new_state = %{
      current_stats: reset_stats,
      last_update: DateTime.utc_now(),
      update_count: 0
    }
    
    {:reply, :ok, new_state}
  end
  
  @impl true
  def handle_info({:sync_with_db}, state) do
    # Periodic synchronization with database (if needed)
    fresh_stats = Stats.calculate_stats_from_db()
    
    # Only update if there's a significant difference
    if significant_difference?(state.current_stats, fresh_stats) do
      StatsCache.set_stats(fresh_stats)
      Broadcaster.broadcast_stats_update(fresh_stats)
      
      Logger.info("Stats synchronized with database due to discrepancy")
      {:noreply, %{state | current_stats: fresh_stats, last_update: DateTime.utc_now()}}
    else
      {:noreply, state}
    end
  end
  
  @impl true
  def handle_info(msg, state) do
    Logger.debug("StatsAggregator received unexpected message: #{inspect(msg)}")
    {:noreply, state}
  end
  
  # Private functions
  
  defp update_stats_for_invoice(current_stats, invoice) do
    total_amount = Decimal.to_float(invoice.total_amount)
    vat_amount = Decimal.to_float(invoice.vat_amount)
    subtotal = Decimal.to_float(invoice.subtotal)
    
    new_count = current_stats.count + 1
    new_total_amount = current_stats.total_amount + total_amount
    new_vat_total = current_stats.vat_total + vat_amount
    new_subtotal = current_stats.subtotal + subtotal
    new_average = new_total_amount / new_count
    
    %{
      count: new_count,
      total_amount: new_total_amount,
      vat_total: new_vat_total,
      subtotal: new_subtotal,
      average_amount: new_average
    }
  end
  
  defp significant_difference?(stats1, stats2) do
    # Check if count differs by more than 1 or amounts differ by more than $1
    count_diff = abs(stats1.count - stats2.count)
    amount_diff = abs(stats1.total_amount - stats2.total_amount)
    
    count_diff > 1 or amount_diff > 1.0
  end
end