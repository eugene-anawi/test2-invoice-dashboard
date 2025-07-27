defmodule Test2Web.DashboardChannel do
  @moduledoc """
  WebSocket channel for real-time dashboard updates.
  Connects to existing PubSub system for live data.
  """
  
  use Test2Web, :channel
  
  alias Test2.Streaming.Broadcaster
  alias Test2.Invoices.Stats
  alias Test2.Streaming.Coordinator
  alias Decimal
  
  @impl true
  def join("dashboard:live", _payload, socket) do
    # Subscribe to existing PubSub topics
    Phoenix.PubSub.subscribe(Test2.PubSub, Broadcaster.invoice_topic())
    Phoenix.PubSub.subscribe(Test2.PubSub, Broadcaster.stats_topic())
    Phoenix.PubSub.subscribe(Test2.PubSub, Broadcaster.system_topic())
    
    # Send initial data
    initial_stats = Stats.get_current_stats()
    system_status = Coordinator.get_status()
    recent_invoices = Stats.get_recent_invoices(20)
    
    push(socket, "initial_data", %{
      stats: format_stats(initial_stats),
      system_status: format_system_status(system_status),
      invoices: format_invoices(recent_invoices)
    })
    
    {:ok, socket}
  end
  
  @impl true
  def handle_info({:new_invoice, invoice}, socket) do
    push(socket, "new_invoice", %{
      invoice: format_invoice(invoice)
    })
    {:noreply, socket}
  end
  
  @impl true
  def handle_info({:stats_update, stats}, socket) do
    push(socket, "stats_update", %{
      stats: format_stats(stats)
    })
    {:noreply, socket}
  end
  
  @impl true
  def handle_info({:status_change, status, system_state}, socket) do
    push(socket, "status_change", %{
      status: status,
      system_status: format_system_status(system_state)
    })
    {:noreply, socket}
  end
  
  # Handle any other messages gracefully
  @impl true
  def handle_info(_msg, socket) do
    {:noreply, socket}
  end
  
  # Private helper functions to format data for JSON
  defp format_stats(stats) do
    %{
      count: stats.count,
      total_amount: stats.total_amount,
      vat_total: stats.vat_total,
      subtotal: stats.subtotal,
      average_amount: stats.average_amount
    }
  end
  
  defp format_system_status(status) do
    %{
      status: status.status,
      total_generated: status.total_generated,
      total_displayed: status.total_displayed,
      running: status.status == :running
    }
  end
  
  defp format_invoices(invoices) do
    Enum.map(invoices, &format_invoice/1)
  end
  
  defp format_invoice(invoice) do
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
  end
end