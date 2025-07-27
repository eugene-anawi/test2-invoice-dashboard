<script>
  export let invoices;
  export let autoScroll;
  
  let gridContainer;
  
  // Auto-scroll to bottom when new invoices arrive
  $: if (autoScroll && invoices && gridContainer) {
    setTimeout(() => {
      gridContainer.scrollTop = gridContainer.scrollHeight;
    }, 100);
  }
  
  function formatCurrency(value) {
    if (!value) return 'R 0.00';
    return `R ${parseFloat(value).toFixed(2)}`;
  }
  
  function formatDate(dateString) {
    if (!dateString) return '';
    const date = new Date(dateString);
    return date.toLocaleDateString('en-ZA', { 
      year: '2-digit', 
      month: '2-digit', 
      day: '2-digit' 
    });
  }
  
  function formatTime(dateString) {
    if (!dateString) return '';
    const date = new Date(dateString);
    return date.toLocaleTimeString('en-ZA', { 
      hour: '2-digit', 
      minute: '2-digit',
      second: '2-digit'
    });
  }
</script>

<div class="invoice-section">
  <div class="section-header">
    <h3>Live Invoice Stream</h3>
    <span class="invoice-count">{invoices?.length || 0} invoices</span>
  </div>
  
  <div class="invoice-grid" bind:this={gridContainer}>
    <div class="grid-header">
      <div class="col-number">Invoice #</div>
      <div class="col-date">Date</div>
      <div class="col-time">Time</div>
      <div class="col-seller">Seller</div>
      <div class="col-buyer">Buyer</div>
      <div class="col-subtotal">Subtotal</div>
      <div class="col-vat">VAT</div>
      <div class="col-total">Total</div>
    </div>
    
    <div class="grid-body">
      {#each (invoices || []) as invoice (invoice.id)}
        <div class="grid-row">
          <div class="col-number">{invoice.invoice_number}</div>
          <div class="col-date">{formatDate(invoice.invoice_date)}</div>
          <div class="col-time">{formatTime(invoice.inserted_at)}</div>
          <div class="col-seller" title={invoice.seller_name}>{invoice.seller_name}</div>
          <div class="col-buyer" title={invoice.buyer_name}>{invoice.buyer_name}</div>
          <div class="col-subtotal">{formatCurrency(invoice.subtotal)}</div>
          <div class="col-vat">{formatCurrency(invoice.vat_amount)}</div>
          <div class="col-total">{formatCurrency(invoice.total_amount)}</div>
        </div>
      {/each}
    </div>
  </div>
</div>

<style>
  .invoice-section {
    width: 100%;
    height: 600px;
    background: white;
    border-radius: 6px;
    border: 1px solid #e2e8f0;
    margin: 0 24px;
    box-sizing: border-box;
    display: flex;
    flex-direction: column;
  }
  
  .section-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 12px 16px;
    border-bottom: 1px solid #e2e8f0;
  }
  
  .section-header h3 {
    margin: 0;
    font-size: 16px;
    font-weight: 600;
    color: #1e293b;
  }
  
  .invoice-count {
    font-size: 12px;
    color: #64748b;
    background: #f1f5f9;
    padding: 2px 8px;
    border-radius: 12px;
  }
  
  .invoice-grid {
    flex: 1;
    overflow-y: auto;
    font-size: 12px;
  }
  
  .grid-header {
    display: grid;
    grid-template-columns: 80px 70px 70px 1fr 1fr 80px 70px 80px;
    gap: 8px;
    padding: 8px 16px;
    background: #f8fafc;
    border-bottom: 1px solid #e2e8f0;
    font-weight: 600;
    color: #374151;
    position: sticky;
    top: 0;
  }
  
  .grid-body {
    display: flex;
    flex-direction: column;
  }
  
  .grid-row {
    display: grid;
    grid-template-columns: 80px 70px 70px 1fr 1fr 80px 70px 80px;
    gap: 8px;
    padding: 6px 16px;
    border-bottom: 1px solid #f1f5f9;
    transition: background-color 0.2s;
  }
  
  .grid-row:hover {
    background-color: #f8fafc;
  }
  
  .grid-row:nth-child(even) {
    background-color: #fefefe;
  }
  
  /* Column styling */
  .col-number {
    font-weight: 500;
    color: #3b82f6;
  }
  
  .col-date, .col-time {
    color: #64748b;
    font-size: 11px;
  }
  
  .col-seller, .col-buyer {
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
    color: #374151;
  }
  
  .col-subtotal, .col-vat, .col-total {
    text-align: right;
    font-weight: 500;
    color: #059669;
  }
  
  .col-total {
    font-weight: 600;
    color: #1e293b;
  }
  
  /* Scrollbar styling */
  .invoice-grid::-webkit-scrollbar {
    width: 6px;
  }
  
  .invoice-grid::-webkit-scrollbar-track {
    background: #f1f5f9;
  }
  
  .invoice-grid::-webkit-scrollbar-thumb {
    background: #cbd5e1;
    border-radius: 3px;
  }
  
  .invoice-grid::-webkit-scrollbar-thumb:hover {
    background: #94a3b8;
  }
</style>