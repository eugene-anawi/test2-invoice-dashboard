defmodule Test2.Invoices.Stats do
  @moduledoc """
  Calculates and manages invoice statistics for the real-time dashboard.
  
  Provides functions to calculate totals, counts, and other metrics
  from invoice data, with Redis caching support.
  """
  
  import Ecto.Query
  alias Test2.Repo
  alias Test2.Invoices.Invoice
  alias Test2.Cache.StatsCache
  
  @doc """
  Gets current invoice statistics including count, total amount, and VAT total.
  
  Returns a map with:
  - count: total number of invoices
  - total_amount: sum of all invoice totals
  - vat_total: sum of all VAT amounts
  - average_amount: average invoice total
  """
  def get_current_stats do
    # Try to get from cache first
    case StatsCache.get_stats() do
      {:ok, stats} -> stats
      {:error, _} -> calculate_stats_from_db()
    end
  end
  
  @doc """
  Calculates statistics directly from the database.
  Used as fallback when cache is unavailable or for cache refresh.
  """
  def calculate_stats_from_db do
    query = from i in Invoice,
      select: %{
        count: count(i.id),
        total_amount: coalesce(sum(i.total_amount), 0),
        vat_total: coalesce(sum(i.vat_amount), 0),
        subtotal: coalesce(sum(i.subtotal), 0)
      }
      
    case Repo.one(query) do
      nil -> 
        default_stats()
      result ->
        stats = %{
          count: result.count,
          total_amount: Decimal.to_float(result.total_amount || Decimal.new(0)),
          vat_total: Decimal.to_float(result.vat_total || Decimal.new(0)),
          subtotal: Decimal.to_float(result.subtotal || Decimal.new(0)),
          average_amount: calculate_average(result.total_amount, result.count)
        }
        
        # Cache the result
        StatsCache.set_stats(stats)
        stats
    end
  end
  
  @doc """
  Updates statistics incrementally when a new invoice is added.
  This is more efficient than recalculating from scratch.
  """
  def update_stats_for_new_invoice(invoice) do
    current_stats = get_current_stats()
    
    new_stats = %{
      count: current_stats.count + 1,
      total_amount: current_stats.total_amount + Decimal.to_float(invoice.total_amount),
      vat_total: current_stats.vat_total + Decimal.to_float(invoice.vat_amount),
      subtotal: current_stats.subtotal + Decimal.to_float(invoice.subtotal),
      average_amount: calculate_average_incremental(
        current_stats.total_amount,
        Decimal.to_float(invoice.total_amount),
        current_stats.count + 1
      )
    }
    
    # Update cache
    StatsCache.set_stats(new_stats)
    
    new_stats
  end
  
  @doc """
  Gets the most recent invoices for display.
  """
  def get_recent_invoices(limit \\ 50) do
    Invoice
    |> order_by(desc: :invoice_date, desc: :inserted_at)
    |> limit(^limit)
    |> Repo.all()
  end
  
  @doc """
  Gets invoices created within the last N seconds.
  Useful for real-time streaming display.
  """
  def get_invoices_since(seconds_ago) do
    cutoff_time = DateTime.utc_now() |> DateTime.add(-seconds_ago, :second)
    
    Invoice
    |> where([i], i.inserted_at >= ^cutoff_time)
    |> order_by(desc: :invoice_date, desc: :inserted_at)
    |> Repo.all()
  end
  
  @doc """
  Resets all statistics (useful for testing)
  """
  def reset_stats do
    StatsCache.clear_stats()
    default_stats()
  end
  
  defp default_stats do
    %{
      count: 0,
      total_amount: 0.0,
      vat_total: 0.0,
      subtotal: 0.0,
      average_amount: 0.0
    }
  end
  
  defp calculate_average(total_amount, count) when count > 0 do
    Decimal.to_float(total_amount || Decimal.new(0)) / count
  end
  defp calculate_average(_, _), do: 0.0
  
  defp calculate_average_incremental(current_total, new_amount, new_count) when new_count > 0 do
    (current_total + new_amount) / new_count
  end
  defp calculate_average_incremental(_, _, _), do: 0.0
end