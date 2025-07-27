defmodule Test2Web.DashboardLive do
  @moduledoc """
  Main Dashboard LiveView for the real-time invoice streaming application.
  
  Displays:
  - Start/Stop controls in sidebar
  - Real-time statistics cards (count, total, VAT)
  - Auto-scrolling invoice grid
  - System status information
  """
  
  use Test2Web, :live_view
  
  alias Test2.Streaming.Coordinator
  alias Test2.Streaming.Broadcaster
  alias Test2.Invoices.Stats
  
  # Helper function to format currency with commas
  defp format_currency(amount) when is_float(amount) do
    amount
    |> :erlang.float_to_binary(decimals: 2)
    |> add_commas()
  end
  
  defp format_currency(amount) when is_binary(amount) do
    add_commas(amount)
  end
  
  defp add_commas(number_string) do
    [integer_part, decimal_part] = String.split(number_string, ".")
    
    integer_part
    |> String.reverse()
    |> String.graphemes()
    |> Enum.chunk_every(3)
    |> Enum.map(&Enum.join/1)
    |> Enum.join(",")
    |> String.reverse()
    |> Kernel.<>("." <> decimal_part)
  end
  
  @impl true
  def mount(_params, _session, socket) do
    # Subscribe to real-time updates
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Test2.PubSub, Broadcaster.invoice_topic())
      Phoenix.PubSub.subscribe(Test2.PubSub, Broadcaster.stats_topic())
      Phoenix.PubSub.subscribe(Test2.PubSub, Broadcaster.system_topic())
    end
    
    # Get initial data
    initial_stats = Stats.get_current_stats()
    system_status = Coordinator.get_status()
    recent_invoices = Stats.get_recent_invoices(20)
    
    socket = 
      socket
      |> assign(:stats, initial_stats)
      |> assign(:system_status, system_status)
      |> stream(:invoices, recent_invoices, limit: 100)
      |> assign(:page_title, "Real-time Invoice Dashboard")
      |> assign(:sidebar_open, true)
      |> assign(:auto_scroll, true)
      |> assign(:display_rate, "2/sec")
      |> assign(:generation_rate, "5/sec")
    
    {:ok, socket}
  end
  
  @impl true
  def handle_event("start_generation", _params, socket) do
    case Coordinator.start_generation() do
      {:ok, :started} ->
        {:noreply, socket}
        
      {:error, :already_running} ->
        {:noreply, socket}
        
      {:error, reason} ->
        {:noreply, socket}
    end
  end
  
  @impl true
  def handle_event("stop_generation", _params, socket) do
    case Coordinator.stop_generation() do
      {:ok, :stopping} ->
        {:noreply, socket}
        
      {:error, :already_stopped} ->
        {:noreply, socket}
        
      {:error, reason} ->
        {:noreply, socket}
    end
  end
  
  @impl true
  def handle_event("reset_system", _params, socket) do
    :ok = Coordinator.reset_system()
    socket = 
      socket
      |> stream(:invoices, [], reset: true)
    {:noreply, socket}
  end
  
  @impl true
  def handle_event("toggle_sidebar", _params, socket) do
    {:noreply, assign(socket, :sidebar_open, !socket.assigns.sidebar_open)}
  end
  
  @impl true
  def handle_event("toggle_auto_scroll", _params, socket) do
    new_auto_scroll = !socket.assigns.auto_scroll
    
    # Send JavaScript command to toggle auto-scrolling
    socket = 
      socket
      |> assign(:auto_scroll, new_auto_scroll)
      |> push_event("toggle_auto_scroll", %{enabled: new_auto_scroll})
    
    {:noreply, socket}
  end
  
  @impl true
  def handle_event("scroll-to-top", _params, socket) do
    # When user scrolls to top, could load older invoices here if needed
    # For now, just log the event
    IO.puts("Scrolled to top of invoice list")
    {:noreply, socket}
  end
  
  @impl true
  def handle_event("scroll-to-bottom", _params, socket) do
    # When user scrolls to bottom, could load more invoices here if needed
    # For now, just log the event
    IO.puts("Scrolled to bottom of invoice list")
    {:noreply, socket}
  end
  
  @impl true
  def handle_info({:new_invoice, invoice}, socket) do
    # Insert new invoice at the top of the stream
    # LiveView streams automatically handle the limit and DOM updates
    socket = 
      socket
      |> stream_insert(:invoices, invoice, at: 0)
      |> push_event("new_invoice", %{invoice: invoice})
    
    {:noreply, socket}
  end
  
  @impl true
  def handle_info({:stats_update, stats}, socket) do
    {:noreply, assign(socket, :stats, stats)}
  end
  
  @impl true
  def handle_info({:status_change, status, system_state}, socket) do
    socket = 
      socket
      |> assign(:system_status, system_state)
    
    {:noreply, socket}
  end
  
  @impl true
  def handle_info(msg, socket) do
    # Handle unexpected messages gracefully
    IO.puts("Unexpected message in DashboardLive: #{inspect(msg)}")
    {:noreply, socket}
  end
  
  @impl true
  def render(assigns) do
    ~H"""
    <!-- Main Dashboard Container - Clean Svelte-Style Layout -->
    <div class="dashboard-container">
      <!-- Control Panel Fixed Top-Right -->
      <div class="control-panel">
        <button 
          phx-click="start_generation"
          disabled={@system_status.status == :running}
          class={[
            "control-btn",
            if(@system_status.status == :running, do: "btn-disabled", else: "btn-start")
          ]}
        >
          <%= if @system_status.status == :running, do: "GENERATING...", else: "START" %>
        </button>
        
        <button 
          phx-click="stop_generation"
          disabled={@system_status.status == :stopped}
          class={[
            "control-btn",
            if(@system_status.status == :stopped, do: "btn-disabled", else: "btn-stop")
          ]}
        >
          STOP
        </button>
        
        <button 
          phx-click="reset_system"
          class="control-btn btn-reset"
        >
          RESET
        </button>
        
        <!-- Status Badge -->
        <div class={[
          "status-badge-panel",
          case @system_status.status do
            :running -> "status-running"
            :stopping -> "status-stopping"
            :stopped -> "status-stopped"
            _ -> "status-default"
          end
        ]}>
          <%= String.upcase(to_string(@system_status.status)) %>
        </div>
      </div>


      <!-- Section 1: Header (60px) -->
      <header class="header">
        <h1 class="title">Real-time Invoice Dashboard</h1>
        <div class="rates">
          <div class="rate-item">
            <div class="pulse-dot generation"></div>
            <span>Generation: <strong><%= @generation_rate %></strong></span>
          </div>
          <div class="rate-item">
            <div class="pulse-dot display"></div>
            <span>Display: <strong><%= @display_rate %></strong></span>
          </div>
        </div>
      </header>

      <!-- Section 2: Statistics Strip (40px) -->
      <div class="stats-strip">
        <div class="stats-left">
          <div class="aligned-items">
            <div class="rate-item">
              <span>Generation: <strong><%= @generation_rate %></strong></span>
            </div>
            <div class="rate-item">
              <span>Display: <strong><%= @display_rate %></strong></span>
            </div>
          </div>
        </div>
        <div class="stats-right">
          <span>Generated: <strong><%= @system_status.total_generated %></strong></span>
          <span>Displayed: <strong><%= @system_status.total_displayed %></strong></span>
          <span>Auto-scroll: 
            <button phx-click="toggle_auto_scroll" class="auto-scroll-btn">
              <strong><%= if @auto_scroll, do: "ON", else: "OFF" %></strong>
            </button>
          </span>
        </div>
      </div>

      <!-- Section 3: TOTALS Cards (80px) -->
      <div class="totals-container">
        <div class="totals-grid">
          <div class="total-card">
            <div class="card-value"><%= @stats.count %></div>
            <div class="card-label">Total Invoices</div>
          </div>
          
          <div class="total-card">
            <div class="card-value">$<%= format_currency(@stats.total_amount) %></div>
            <div class="card-label">Total Value</div>
          </div>
          
          <div class="total-card">
            <div class="card-value">$<%= format_currency(@stats.vat_total) %></div>
            <div class="card-label">Total VAT</div>
          </div>
          
          <div class="total-card">
            <div class="card-value">$<%= format_currency(@stats.average_amount) %></div>
            <div class="card-label">Average Value</div>
          </div>
        </div>
      </div>

      <!-- Section 4: Invoice Grid (600px) -->
      <div class="invoice-section">
        <div class="section-header">
          <h3>Live Invoice Stream</h3>
        </div>
        
        <div 
          id="invoice-grid" 
          phx-hook="InvoiceGrid"
          class="invoice-grid"
          data-auto-scroll={@auto_scroll}
          phx-viewport-top={@auto_scroll && "scroll-to-top"}
          phx-viewport-bottom={@auto_scroll && "scroll-to-bottom"}
        >
          <div class="grid-header">
            <div class="col-number">Invoice #</div>
            <div class="col-date">Date</div>
            <div class="col-seller">Seller</div>
            <div class="col-buyer">Buyer</div>
            <div class="col-subtotal">Subtotal</div>
            <div class="col-vat">VAT</div>
            <div class="col-total">Total</div>
            <div class="col-export">Export Country</div>
            <div class="col-import">Import Country</div>
            <div class="col-payment">Payment</div>
            <div class="col-risk">Risk</div>
          </div>
          
          <!-- LiveView Stream Container -->
          <div phx-update="stream" id="invoices" class="grid-body invoice-stream">
            <%= for {dom_id, invoice} <- @streams.invoices do %>
              <div id={dom_id} class="grid-row invoice-row">
                <div class="col-number"><%= invoice.invoice_number %></div>
                <div class="col-date"><%= Date.to_string(invoice.invoice_date) %></div>
                <div class="col-seller" title={invoice.seller_name}><%= invoice.seller_name %></div>
                <div class="col-buyer" title={invoice.buyer_name}><%= invoice.buyer_name %></div>
                <div class="col-subtotal">$<%= format_currency(Decimal.to_string(invoice.total_amount |> Decimal.mult(Decimal.new("0.85")))) %></div>
                <div class="col-vat">$<%= format_currency(Decimal.to_string(invoice.vat_amount)) %></div>
                <div class="col-total">$<%= format_currency(Decimal.to_string(invoice.total_amount)) %></div>
                <div class="col-export" title={invoice.exporting_country}><%= invoice.exporting_country %></div>
                <div class="col-import" title={invoice.importing_country}><%= invoice.importing_country %></div>
                <div class="col-payment" title={invoice.payment_mechanism}><%= invoice.payment_mechanism %></div>
                <div class={[
                  "col-risk",
                  case invoice.risk_profile do
                    "Green" -> "risk-green"
                    "Amber" -> "risk-amber"
                    "Red" -> "risk-red"
                    _ -> ""
                  end
                ]}><%= invoice.risk_profile %></div>
              </div>
            <% end %>
          </div>
          
          <!-- Empty state -->
          <div class="empty-state" style={if @streams.invoices != [], do: "display: none"}>
            <p>No invoices yet</p>
            <p>Click "START" to begin generation</p>
          </div>
        </div>
      </div>
    </div>
    """
  end
end