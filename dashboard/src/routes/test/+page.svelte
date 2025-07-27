<script>
  import { onMount } from 'svelte';
  
  let testResults = [];
  let isTestingAPI = false;
  let isTestingWebSocket = false;
  
  async function testAPI() {
    isTestingAPI = true;
    testResults = [];
    
    const apiTests = [
      { name: 'Test Stats API', url: 'http://localhost:4000/api/stats' },
      { name: 'Test Status API', url: 'http://localhost:4000/api/system/status' },
      { name: 'Test Invoices API', url: 'http://localhost:4000/api/invoices' }
    ];
    
    for (const test of apiTests) {
      try {
        const response = await fetch(test.url);
        const data = await response.json();
        testResults = [...testResults, {
          name: test.name,
          status: response.ok ? 'PASS' : 'FAIL',
          details: `Status: ${response.status}, Data: ${JSON.stringify(data).substring(0, 100)}...`
        }];
      } catch (error) {
        testResults = [...testResults, {
          name: test.name,
          status: 'ERROR',
          details: `Error: ${error.message}`
        }];
      }
    }
    
    isTestingAPI = false;
  }
  
  async function testWebSocket() {
    isTestingWebSocket = true;
    
    try {
      const { Socket } = await import('phoenix');
      const socket = new Socket('ws://localhost:4000/socket');
      
      socket.onOpen(() => {
        testResults = [...testResults, {
          name: 'WebSocket Connection',
          status: 'PASS',
          details: 'Successfully connected to Phoenix WebSocket'
        }];
        
        const channel = socket.channel('dashboard:live', {});
        channel.join()
          .receive('ok', () => {
            testResults = [...testResults, {
              name: 'Channel Join',
              status: 'PASS',
              details: 'Successfully joined dashboard:live channel'
            }];
          })
          .receive('error', (error) => {
            testResults = [...testResults, {
              name: 'Channel Join',
              status: 'FAIL',
              details: `Failed to join channel: ${JSON.stringify(error)}`
            }];
          });
      });
      
      socket.onError((error) => {
        testResults = [...testResults, {
          name: 'WebSocket Connection',
          status: 'ERROR',
          details: `WebSocket error: ${error.message || 'Unknown error'}`
        }];
      });
      
      socket.connect();
      
      // Timeout after 5 seconds
      setTimeout(() => {
        socket.disconnect();
        isTestingWebSocket = false;
      }, 5000);
      
    } catch (error) {
      testResults = [...testResults, {
        name: 'WebSocket Setup',
        status: 'ERROR',
        details: `Setup error: ${error.message}`
      }];
      isTestingWebSocket = false;
    }
  }
  
  async function testControlAPI() {
    const controlTests = [
      { name: 'Test Start Generation', url: 'http://localhost:4000/api/control/start', method: 'POST' },
      { name: 'Test Stop Generation', url: 'http://localhost:4000/api/control/stop', method: 'POST' },
      { name: 'Test Reset System', url: 'http://localhost:4000/api/control/reset', method: 'POST' }
    ];
    
    for (const test of controlTests) {
      try {
        const response = await fetch(test.url, {
          method: test.method,
          headers: { 'Content-Type': 'application/json' }
        });
        const data = await response.json();
        testResults = [...testResults, {
          name: test.name,
          status: response.ok ? 'PASS' : 'FAIL',
          details: `Status: ${response.status}, Message: ${data.message || data.error || 'No message'}`
        }];
      } catch (error) {
        testResults = [...testResults, {
          name: test.name,
          status: 'ERROR',
          details: `Error: ${error.message}`
        }];
      }
    }
  }
  
  function clearResults() {
    testResults = [];
  }
</script>

<svelte:head>
  <title>Phoenix API & WebSocket Test</title>
</svelte:head>

<div class="test-container">
  <h1>Phoenix Backend Test Suite</h1>
  
  <div class="test-controls">
    <button on:click={testAPI} disabled={isTestingAPI}>
      {isTestingAPI ? 'Testing API...' : 'Test API Endpoints'}
    </button>
    
    <button on:click={testWebSocket} disabled={isTestingWebSocket}>
      {isTestingWebSocket ? 'Testing WebSocket...' : 'Test WebSocket'}
    </button>
    
    <button on:click={testControlAPI}>
      Test Control Actions
    </button>
    
    <button on:click={clearResults}>
      Clear Results
    </button>
  </div>
  
  <div class="results-section">
    <h2>Test Results ({testResults.length})</h2>
    {#each testResults as result}
      <div class="test-result {result.status.toLowerCase()}">
        <div class="result-header">
          <span class="test-name">{result.name}</span>
          <span class="test-status {result.status.toLowerCase()}">{result.status}</span>
        </div>
        <div class="result-details">{result.details}</div>
      </div>
    {/each}
    
    {#if testResults.length === 0}
      <div class="no-results">
        No test results yet. Click a test button above to start testing.
      </div>
    {/if}
  </div>
  
  <div class="instructions">
    <h3>Instructions:</h3>
    <ol>
      <li>Make sure Phoenix server is running: <code>cd /home/server3/test2 && mix phx.server</code></li>
      <li>Test API endpoints first to verify basic connectivity</li>
      <li>Test WebSocket connection to verify real-time functionality</li>
      <li>Test control actions to verify dashboard functionality</li>
    </ol>
  </div>
</div>

<style>
  .test-container {
    max-width: 800px;
    margin: 20px auto;
    padding: 20px;
    font-family: -apple-system, BlinkMacSystemFont, sans-serif;
  }
  
  h1 {
    color: #2563eb;
    border-bottom: 2px solid #e5e7eb;
    padding-bottom: 10px;
  }
  
  .test-controls {
    display: flex;
    gap: 10px;
    margin: 20px 0;
    flex-wrap: wrap;
  }
  
  button {
    padding: 10px 20px;
    background: #3b82f6;
    color: white;
    border: none;
    border-radius: 6px;
    cursor: pointer;
    font-weight: 500;
  }
  
  button:hover:not(:disabled) {
    background: #2563eb;
  }
  
  button:disabled {
    background: #9ca3af;
    cursor: not-allowed;
  }
  
  .results-section {
    margin: 20px 0;
  }
  
  .test-result {
    margin: 10px 0;
    padding: 15px;
    border-radius: 6px;
    border-left: 4px solid;
  }
  
  .test-result.pass {
    background: #f0f9ff;
    border-color: #10b981;
  }
  
  .test-result.fail {
    background: #fef2f2;
    border-color: #ef4444;
  }
  
  .test-result.error {
    background: #fffbeb;
    border-color: #f59e0b;
  }
  
  .result-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 5px;
  }
  
  .test-name {
    font-weight: 600;
    color: #374151;
  }
  
  .test-status {
    padding: 2px 8px;
    border-radius: 4px;
    font-size: 12px;
    font-weight: 600;
  }
  
  .test-status.pass {
    background: #dcfce7;
    color: #166534;
  }
  
  .test-status.fail {
    background: #fee2e2;
    color: #991b1b;
  }
  
  .test-status.error {
    background: #fef3c7;
    color: #92400e;
  }
  
  .result-details {
    font-size: 14px;
    color: #6b7280;
    font-family: monospace;
    background: #f9fafb;
    padding: 8px;
    border-radius: 4px;
    word-break: break-all;
  }
  
  .no-results {
    text-align: center;
    color: #6b7280;
    font-style: italic;
    padding: 40px 20px;
  }
  
  .instructions {
    background: #f8fafc;
    padding: 20px;
    border-radius: 8px;
    margin-top: 30px;
  }
  
  .instructions h3 {
    margin-top: 0;
    color: #374151;
  }
  
  .instructions ol {
    margin: 10px 0;
  }
  
  .instructions li {
    margin: 8px 0;
    color: #4b5563;
  }
  
  code {
    background: #e5e7eb;
    padding: 2px 6px;
    border-radius: 3px;
    font-family: monospace;
    font-size: 14px;
  }
</style>