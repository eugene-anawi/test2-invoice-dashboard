<script>
  export let systemStatus;
  export let autoScroll;
  
  // Import control functions from store
  import { startGeneration, stopGeneration, resetSystem, toggleAutoScroll } from '$lib/stores/dashboard.js';
  
  async function handleStart() {
    await startGeneration();
  }
  
  async function handleStop() {
    await stopGeneration();
  }
  
  async function handleReset() {
    await resetSystem();
  }
  
  // Debug: log systemStatus changes (remove this after testing)
  $: if (systemStatus) {
    console.log('StatsStrip systemStatus:', systemStatus);
  }
</script>

<div class="stats-strip">
  <div class="status-section">
    <div class="status-indicator {systemStatus?.running ? 'running' : 'stopped'}">
      {systemStatus?.running ? 'RUNNING' : 'STOPPED'}
    </div>
    <span class="status-text">
      Generated: {systemStatus?.total_generated || 0} | 
      Displayed: {systemStatus?.total_displayed || 0} |
      Running: {systemStatus?.running} | 
      Status: {systemStatus?.status || 'unknown'}
    </span>
  </div>
  
  <div class="controls-section">
    <button 
      class="control-btn start" 
      on:click={handleStart}
      disabled={systemStatus?.running}
    >
      START
    </button>
    <button 
      class="control-btn stop" 
      on:click={handleStop}
      disabled={!systemStatus?.running}
    >
      STOP
    </button>
    <button 
      class="control-btn reset" 
      on:click={handleReset}
    >
      RESET
    </button>
  </div>
  
  <div class="scroll-section">
    <label class="scroll-toggle">
      <input 
        type="checkbox" 
        checked={autoScroll}
        on:change={toggleAutoScroll}
      />
      Auto-scroll
    </label>
  </div>
</div>

<style>
  .stats-strip {
    width: 100%;
    height: 40px;
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 0 24px;
    background: #f1f5f9;
    border-bottom: 1px solid #e2e8f0;
    box-sizing: border-box;
    font-size: 13px;
  }
  
  .status-section {
    display: flex;
    align-items: center;
    gap: 16px;
  }
  
  .status-indicator {
    padding: 4px 12px;
    border-radius: 12px;
    font-size: 11px;
    font-weight: 600;
    letter-spacing: 0.5px;
  }
  
  .status-indicator.running {
    background-color: #dcfce7;
    color: #166534;
  }
  
  .status-indicator.stopped {
    background-color: #fee2e2;
    color: #991b1b;
  }
  
  .status-text {
    color: #64748b;
    font-weight: 500;
  }
  
  .controls-section {
    display: flex;
    gap: 8px;
  }
  
  .control-btn {
    padding: 4px 16px;
    border: 1px solid #d1d5db;
    border-radius: 4px;
    background: white;
    color: #374151;
    font-size: 11px;
    font-weight: 600;
    cursor: pointer;
    transition: all 0.2s;
  }
  
  .control-btn:hover:not(:disabled) {
    background: #f9fafb;
    border-color: #9ca3af;
  }
  
  .control-btn:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }
  
  .control-btn.start:not(:disabled) {
    background: #10b981;
    color: white;
    border-color: #10b981;
  }
  
  .control-btn.stop:not(:disabled) {
    background: #ef4444;
    color: white;
    border-color: #ef4444;
  }
  
  .control-btn.reset {
    background: #6366f1;
    color: white;
    border-color: #6366f1;
  }
  
  .scroll-section {
    display: flex;
    align-items: center;
  }
  
  .scroll-toggle {
    display: flex;
    align-items: center;
    gap: 6px;
    font-size: 12px;
    color: #64748b;
    cursor: pointer;
  }
  
  .scroll-toggle input[type="checkbox"] {
    width: 14px;
    height: 14px;
    cursor: pointer;
  }
</style>