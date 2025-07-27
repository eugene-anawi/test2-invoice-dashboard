defmodule Test2Web.Api.DashboardController do
  @moduledoc """
  API controller for Svelte frontend dashboard.
  Provides JSON endpoints for dashboard data and controls.
  """
  
  use Test2Web, :controller
  
  alias Test2.Streaming.Coordinator
  alias Test2.Invoices.Stats
  alias Decimal
  
  @doc """
  GET /api/stats
  Returns current statistics as JSON
  """
  def stats(conn, _params) do
    current_stats = Stats.get_current_stats()
    
    json(conn, %{
      success: true,
      data: %{
        count: current_stats.count,
        total_amount: current_stats.total_amount,
        vat_total: current_stats.vat_total,
        subtotal: current_stats.subtotal,
        average_amount: current_stats.average_amount
      }
    })
  end
  
  @doc """
  GET /api/invoices
  Returns recent invoices as JSON
  """
  def invoices(conn, params) do
    limit = Map.get(params, "limit", "20") |> String.to_integer()
    recent_invoices = Stats.get_recent_invoices(limit)
    
    invoices_data = Enum.map(recent_invoices, fn invoice ->
      %{
        id: invoice.id,
        invoice_number: invoice.invoice_number,
        invoice_date: invoice.invoice_date,
        seller_name: invoice.seller_name,
        buyer_name: invoice.buyer_name,
        subtotal: Decimal.to_string(invoice.subtotal),
        vat_amount: Decimal.to_string(invoice.vat_amount),
        total_amount: Decimal.to_string(invoice.total_amount),
        inserted_at: invoice.inserted_at
      }
    end)
    
    json(conn, %{
      success: true,
      data: invoices_data,
      count: length(invoices_data)
    })
  end
  
  @doc """
  GET /api/system/status
  Returns current system status as JSON
  """
  def system_status(conn, _params) do
    status = Coordinator.get_status()
    
    json(conn, %{
      success: true,
      data: %{
        status: status.status,
        total_generated: status.total_generated,
        total_displayed: status.total_displayed,
        running: status.status == :running
      }
    })
  end
  
  @doc """
  POST /api/control/start
  Starts invoice generation
  """
  def start_generation(conn, _params) do
    case Coordinator.start_generation() do
      {:ok, :started} ->
        json(conn, %{
          success: true,
          message: "Invoice generation started",
          status: "running"
        })
        
      {:error, :already_running} ->
        conn
        |> put_status(:conflict)
        |> json(%{
          success: false,
          error: "Generation is already running",
          status: "running"
        })
        
      {:error, reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{
          success: false,
          error: "Failed to start: #{reason}",
          status: "error"
        })
    end
  end
  
  @doc """
  POST /api/control/stop
  Stops invoice generation
  """
  def stop_generation(conn, _params) do
    case Coordinator.stop_generation() do
      {:ok, :stopping} ->
        json(conn, %{
          success: true,
          message: "Stopping generation, processing backlog...",
          status: "stopping"
        })
        
      {:error, :already_stopped} ->
        conn
        |> put_status(:conflict)
        |> json(%{
          success: false,
          error: "Generation is already stopped",
          status: "stopped"
        })
        
      {:error, reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{
          success: false,
          error: "Failed to stop: #{reason}",
          status: "error"
        })
    end
  end
  
  @doc """
  POST /api/control/reset
  Resets the entire system
  """
  def reset_system(conn, _params) do
    :ok = Coordinator.reset_system()
    
    json(conn, %{
      success: true,
      message: "System reset completed",
      status: "stopped"
    })
  end
end