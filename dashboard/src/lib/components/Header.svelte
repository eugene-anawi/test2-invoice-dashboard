<script>
  // No props needed for header - it's static
</script>

<header class="header">
  <h1 class="title">Real-time Invoice Dashboard</h1>
  <div class="rates">
    <div class="rate-item">
      <div class="pulse-dot generation"></div>
      <span>Generation: <strong>5/sec</strong></span>
    </div>
    <div class="rate-item">
      <div class="pulse-dot display"></div>
      <span>Display: <strong>2/sec</strong></span>
    </div>
  </div>
</header>

<style>
  .header {
    width: 100%;
    height: 60px;
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 0 24px;
    background: white;
    border-bottom: 1px solid #e2e8f0;
    box-sizing: border-box;
  }
  
  .title {
    font-size: 20px;
    font-weight: 700;
    color: #1e293b;
    margin: 0;
  }
  
  .rates {
    display: flex;
    gap: 32px;
    font-size: 14px;
    color: #64748b;
  }
  
  .rate-item {
    display: flex;
    align-items: center;
    gap: 8px;
  }
  
  .pulse-dot {
    width: 8px;
    height: 8px;
    border-radius: 50%;
    animation: pulse 2s infinite;
  }
  
  .pulse-dot.generation {
    background-color: #10b981;
  }
  
  .pulse-dot.display {
    background-color: #3b82f6;
  }
  
  @keyframes pulse {
    0%, 100% { opacity: 1; }
    50% { opacity: 0.7; }
  }
  
  strong {
    color: #374151;
    font-weight: 600;
  }
</style>