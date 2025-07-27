<script>
  import { onMount } from 'svelte';
  import Header from '$lib/components/Header.svelte';
  import StatsStrip from '$lib/components/StatsStrip.svelte';
  import TotalsCards from '$lib/components/TotalsCards.svelte';
  import InvoiceGrid from '$lib/components/InvoiceGrid.svelte';
  import { dashboardStore, connectWebSocket, loadInitialData } from '$lib/stores/dashboard.js';
  
  // Reactive variables from store
  $: stats = $dashboardStore.stats;
  $: systemStatus = $dashboardStore.systemStatus;
  $: invoices = $dashboardStore.invoices;
  $: autoScroll = $dashboardStore.autoScroll;
  $: connectionStatus = $dashboardStore.connectionStatus;
  $: lastError = $dashboardStore.lastError;
  $: debugInfo = $dashboardStore.debugInfo;
  
  onMount(async () => {
    console.log('Dashboard mounted, initializing...');
    
    // First, try to load initial data via API
    const apiSuccess = await loadInitialData();
    
    // Then attempt WebSocket connection
    await connectWebSocket();
    
    console.log('Dashboard initialization complete', { apiSuccess, connectionStatus: $dashboardStore.connectionStatus });
  });
</script>

<svelte:head>
  <title>Real-time Invoice Dashboard</title>
</svelte:head>

<!-- Main Dashboard Container - Optimized for 1280x800 -->
<div class="dashboard-container">
  <!-- Connection Status Indicator -->
  {#if connectionStatus !== 'connected'}
    <div class="connection-status {connectionStatus}">
      {#if connectionStatus === 'connecting'}
        🔄 Connecting to server...
      {:else if connectionStatus === 'error'}
        ❌ Connection error: {lastError?.message || 'Unknown error'}
      {:else}
        ⚠️ Disconnected from server
      {/if}
    </div>
  {/if}
  
  <!-- Section 1: Header (60px) -->
  <Header />
  
  <!-- Section 2: Statistics Strip (40px) -->
  <StatsStrip {systemStatus} {autoScroll} />
  
  <!-- Section 3: TOTALS Cards (80px) -->
  <TotalsCards {stats} />
  
  <!-- Section 4: Invoice Grid (600px) -->
  <InvoiceGrid {invoices} {autoScroll} />
  
  <!-- Debug Panel (collapsible) -->
  {#if debugInfo.length > 0}
    <details class="debug-panel">
      <summary>Debug Info ({debugInfo.length} entries)</summary>
      <div class="debug-entries">
        {#each debugInfo.slice(0, 10) as entry}
          <div class="debug-entry">
            <span class="debug-time">{new Date(entry.timestamp).toLocaleTimeString()}</span>
            <span class="debug-message">{entry.message}</span>
            {#if entry.data}
              <pre class="debug-data">{JSON.stringify(entry.data, null, 2)}</pre>
            {/if}
          </div>
        {/each}
      </div>
    </details>
  {/if}
</div>

<style>
  :global(html, body) {
    margin: 0;
    padding: 0;
    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
    background-color: #f8fafc;
  }
  
  .dashboard-container {
    width: 992px; /* 1280px - 288px sidebar = 992px */
    height: 800px;
    margin: 0;
    padding: 0;
    display: flex;
    flex-direction: column;
    background-color: #f8fafc;
    position: relative;
  }
  
  /* Ensure precise layout control */
  .dashboard-container > :global(*) {
    flex-shrink: 0; /* Prevent components from shrinking */
  }
  
  /* Connection status styles */
  .connection-status {
    position: fixed;
    top: 10px;
    right: 10px;
    padding: 8px 16px;
    border-radius: 4px;
    font-size: 12px;
    font-weight: 500;
    z-index: 1000;
    max-width: 300px;
  }
  
  .connection-status.connecting {
    background: #fef3c7;
    color: #92400e;
    border: 1px solid #f59e0b;
  }
  
  .connection-status.error {
    background: #fee2e2;
    color: #991b1b;
    border: 1px solid #dc2626;
  }
  
  .connection-status.disconnected {
    background: #f3f4f6;
    color: #374151;
    border: 1px solid #9ca3af;
  }
  
  /* Debug panel styles */
  .debug-panel {
    position: fixed;
    bottom: 10px;
    right: 10px;
    background: white;
    border: 1px solid #e2e8f0;
    border-radius: 6px;
    max-width: 400px;
    max-height: 300px;
    overflow: auto;
    z-index: 1000;
    font-size: 11px;
  }
  
  .debug-panel summary {
    padding: 8px 12px;
    background: #f8fafc;
    cursor: pointer;
    font-weight: 600;
    border-bottom: 1px solid #e2e8f0;
  }
  
  .debug-entries {
    padding: 8px;
  }
  
  .debug-entry {
    margin-bottom: 8px;
    padding: 4px;
    border-left: 2px solid #e2e8f0;
    padding-left: 8px;
  }
  
  .debug-time {
    font-weight: 600;
    color: #6b7280;
    margin-right: 8px;
  }
  
  .debug-message {
    color: #374151;
  }
  
  .debug-data {
    margin: 4px 0 0 0;
    font-size: 10px;
    background: #f9fafb;
    padding: 4px;
    border-radius: 2px;
    overflow-x: auto;
  }
</style>
