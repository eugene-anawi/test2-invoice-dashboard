<script>
  export let stats;
  
  // Format currency values
  function formatCurrency(value) {
    if (!value) return 'R 0.00';
    return `R ${parseFloat(value).toFixed(2)}`;
  }
  
  function formatNumber(value) {
    if (!value) return '0';
    return value.toLocaleString();
  }
</script>

<div class="totals-container">
  <div class="totals-grid">
    <div class="total-card">
      <div class="card-value">{formatNumber(stats?.count || 0)}</div>
      <div class="card-label">Total Invoices</div>
    </div>
    
    <div class="total-card">
      <div class="card-value">{formatCurrency(stats?.total_amount)}</div>
      <div class="card-label">Total Value</div>
    </div>
    
    <div class="total-card">
      <div class="card-value">{formatCurrency(stats?.vat_total)}</div>
      <div class="card-label">Total VAT</div>
    </div>
    
    <div class="total-card">
      <div class="card-value">{formatCurrency(stats?.average_amount)}</div>
      <div class="card-label">Average Value</div>
    </div>
  </div>
</div>

<style>
  .totals-container {
    width: 100%;
    height: 80px;
    padding: 12px 24px;
    background: white;
    border-bottom: 1px solid #e2e8f0;
    box-sizing: border-box;
  }
  
  .totals-grid {
    width: 100%;
    height: 56px;
    display: grid;
    grid-template-columns: repeat(4, 1fr);
    gap: 16px;
  }
  
  .total-card {
    display: flex;
    flex-direction: column;
    justify-content: center;
    align-items: center;
    background: #f8fafc;
    border: 1px solid #e2e8f0;
    border-radius: 6px;
    padding: 8px;
    box-sizing: border-box;
  }
  
  .card-value {
    font-size: 16px;
    font-weight: 700;
    color: #1e293b;
    line-height: 1;
    margin-bottom: 2px;
  }
  
  .card-label {
    font-size: 11px;
    font-weight: 500;
    color: #64748b;
    text-align: center;
    line-height: 1;
  }
  
  /* Responsive adjustments for smaller content */
  @media (max-width: 1000px) {
    .totals-grid {
      grid-template-columns: repeat(2, 1fr);
      grid-template-rows: repeat(2, 1fr);
      gap: 12px;
    }
    
    .card-value {
      font-size: 14px;
    }
    
    .card-label {
      font-size: 10px;
    }
  }
</style>