import { writable } from 'svelte/store';
import { Socket } from 'phoenix';

// Phoenix server configuration
const PHOENIX_URL = 'ws://localhost:4000/socket';
const API_BASE_URL = 'http://localhost:4000/api';

// Create reactive store
function createDashboardStore() {
  const { subscribe, set, update } = writable({
    stats: {
      count: 0,
      total_amount: '0.00',
      vat_total: '0.00',
      subtotal: '0.00',
      average_amount: '0.00'
    },
    systemStatus: {
      status: 'stopped',
      total_generated: 0,
      total_displayed: 0,
      running: false
    },
    invoices: [],
    autoScroll: true,
    connected: false,
    connectionStatus: 'disconnected', // disconnected, connecting, connected, error
    lastError: null,
    debugInfo: []
  });

  let socket = null;
  let channel = null;
  let reconnectTimer = null;
  let reconnectAttempts = 0;
  const MAX_RECONNECT_ATTEMPTS = 5;

  // Helper function to add debug info
  function addDebugInfo(message, data = null) {
    const timestamp = new Date().toISOString();
    const debugEntry = { timestamp, message, data };
    console.log(`[Dashboard Debug] ${message}`, data || '');
    
    update(store => ({
      ...store,
      debugInfo: [debugEntry, ...store.debugInfo].slice(0, 20) // Keep last 20 entries
    }));
  }

  // Helper function to update connection status
  function updateConnectionStatus(status, error = null) {
    update(store => ({
      ...store,
      connectionStatus: status,
      connected: status === 'connected',
      lastError: error
    }));
  }

  // Helper function to attempt reconnection
  function attemptReconnection() {
    if (reconnectAttempts < MAX_RECONNECT_ATTEMPTS) {
      reconnectAttempts++;
      const delay = Math.min(1000 * Math.pow(2, reconnectAttempts - 1), 10000); // Exponential backoff, max 10s
      
      addDebugInfo(`Attempting reconnection ${reconnectAttempts}/${MAX_RECONNECT_ATTEMPTS} in ${delay}ms`);
      
      reconnectTimer = setTimeout(() => {
        addDebugInfo(`Reconnection attempt ${reconnectAttempts}`);
        connect();
      }, delay);
    } else {
      addDebugInfo('Max reconnection attempts reached, giving up');
      updateConnectionStatus('error', new Error('Max reconnection attempts reached'));
    }
  }

  // Helper function to reset reconnection state
  function resetReconnection() {
    if (reconnectTimer) {
      clearTimeout(reconnectTimer);
      reconnectTimer = null;
    }
    reconnectAttempts = 0;
  }

  // Define connect function that can be called by reconnection logic
  async function connect() {
      addDebugInfo('Starting WebSocket connection', { url: PHOENIX_URL });
      updateConnectionStatus('connecting');
      
      try {
        // Disconnect any existing connection first
        if (socket) {
          addDebugInfo('Disconnecting existing socket');
          socket.disconnect();
        }
        
        socket = new Socket(PHOENIX_URL, {
          logger: (kind, msg, data) => {
            addDebugInfo(`Phoenix ${kind}: ${msg}`, data);
          }
        });
        
        addDebugInfo('Socket created, attempting to connect');
        socket.connect();
        
        channel = socket.channel('dashboard:live', {});
        addDebugInfo('Channel created for dashboard:live');
        
        // Handle initial data
        channel.on('initial_data', (payload) => {
          addDebugInfo('Received initial data from WebSocket', payload);
          update(store => ({
            ...store,
            stats: payload.stats || store.stats,
            systemStatus: payload.system_status || store.systemStatus,
            invoices: payload.invoices || [],
            connected: true
          }));
        });
        
        // Handle new invoices
        channel.on('new_invoice', (payload) => {
          addDebugInfo('New invoice received', payload.invoice);
          update(store => ({
            ...store,
            invoices: [payload.invoice, ...store.invoices].slice(0, 50) // Keep last 50
          }));
        });
        
        // Handle stats updates
        channel.on('stats_update', (payload) => {
          addDebugInfo('Stats update received', payload.stats);
          update(store => ({
            ...store,
            stats: payload.stats
          }));
        });
        
        // Handle status changes
        channel.on('status_change', (payload) => {
          addDebugInfo('Status change received', payload);
          update(store => ({
            ...store,
            systemStatus: payload.system_status
          }));
        });
        
        // Join channel
        channel.join()
          .receive('ok', () => {
            addDebugInfo('Successfully joined dashboard channel');
            updateConnectionStatus('connected');
          })
          .receive('error', (error) => {
            addDebugInfo('Failed to join dashboard channel', error);
            updateConnectionStatus('error', error);
          });
        
        // Handle socket connection events
        socket.onOpen(() => {
          addDebugInfo('Socket connection opened');
          updateConnectionStatus('connected');
          resetReconnection(); // Reset reconnection attempts on successful connection
        });
        
        socket.onError((error) => {
          addDebugInfo('Socket error occurred', error);
          updateConnectionStatus('error', error);
          attemptReconnection();
        });
        
        socket.onClose(() => {
          addDebugInfo('Socket connection closed');
          updateConnectionStatus('disconnected');
          // Only attempt reconnection if we were previously connected
          if (reconnectAttempts === 0) {
            attemptReconnection();
          }
        });
        
      } catch (error) {
        addDebugInfo('Failed to create WebSocket connection', error);
        updateConnectionStatus('error', error);
        attemptReconnection();
      }
    }

  return {
    subscribe,
    
    // WebSocket connection management
    connect,
    
    disconnect: () => {
      addDebugInfo('Manually disconnecting WebSocket');
      resetReconnection();
      
      if (channel) {
        channel.leave();
        channel = null;
      }
      if (socket) {
        socket.disconnect();
        socket = null;
      }
      updateConnectionStatus('disconnected');
    },
    
    // API calls for control actions
    startGeneration: async () => {
      addDebugInfo('Starting generation via API');
      try {
        const response = await fetch(`${API_BASE_URL}/control/start`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          }
        });
        
        addDebugInfo('Start generation API response', { status: response.status, ok: response.ok });
        
        const result = await response.json();
        if (!result.success) {
          throw new Error(result.error || 'Failed to start generation');
        }
        
        addDebugInfo('Generation started successfully', result);
        return result;
      } catch (error) {
        addDebugInfo('Failed to start generation', error);
        throw error;
      }
    },
    
    stopGeneration: async () => {
      addDebugInfo('Stopping generation via API');
      try {
        const response = await fetch(`${API_BASE_URL}/control/stop`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          }
        });
        
        addDebugInfo('Stop generation API response', { status: response.status, ok: response.ok });
        
        const result = await response.json();
        if (!result.success) {
          throw new Error(result.error || 'Failed to stop generation');
        }
        
        addDebugInfo('Generation stopped successfully', result);
        return result;
      } catch (error) {
        addDebugInfo('Failed to stop generation', error);
        throw error;
      }
    },
    
    resetSystem: async () => {
      addDebugInfo('Resetting system via API');
      try {
        const response = await fetch(`${API_BASE_URL}/control/reset`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          }
        });
        
        addDebugInfo('Reset system API response', { status: response.status, ok: response.ok });
        
        const result = await response.json();
        if (!result.success) {
          throw new Error(result.error || 'Failed to reset system');
        }
        
        addDebugInfo('System reset successfully', result);
        // Clear local data
        update(store => ({
          ...store,
          invoices: [],
          stats: {
            count: 0,
            total_amount: '0.00',
            vat_total: '0.00',
            subtotal: '0.00',
            average_amount: '0.00'
          }
        }));
        
        return result;
      } catch (error) {
        addDebugInfo('Failed to reset system', error);
        throw error;
      }
    },
    
    // Toggle auto-scroll
    toggleAutoScroll: () => {
      update(store => ({
        ...store,
        autoScroll: !store.autoScroll
      }));
    },
    
    // Load initial data via API
    loadInitialData: async () => {
      addDebugInfo('Loading initial data via API', { baseUrl: API_BASE_URL });
      
      try {
        addDebugInfo('Making API requests for initial data');
        const [statsResponse, statusResponse, invoicesResponse] = await Promise.all([
          fetch(`${API_BASE_URL}/stats`),
          fetch(`${API_BASE_URL}/system/status`),
          fetch(`${API_BASE_URL}/invoices`)
        ]);
        
        addDebugInfo('API responses received', {
          statsStatus: statsResponse.status,
          statusStatus: statusResponse.status,
          invoicesStatus: invoicesResponse.status
        });
        
        if (!statsResponse.ok || !statusResponse.ok || !invoicesResponse.ok) {
          throw new Error('One or more API requests failed');
        }
        
        const stats = await statsResponse.json();
        const status = await statusResponse.json();
        const invoices = await invoicesResponse.json();
        
        addDebugInfo('API data parsed successfully', {
          statsCount: stats.data?.count,
          systemStatus: status.data?.status,
          invoicesCount: invoices.data?.length
        });
        
        update(store => ({
          ...store,
          stats: stats.data || store.stats,
          systemStatus: status.data || store.systemStatus,
          invoices: invoices.data || []
        }));
        
        addDebugInfo('Initial data loaded and store updated successfully');
        return true;
      } catch (error) {
        addDebugInfo('Failed to load initial data', error);
        updateConnectionStatus('error', error);
        return false;
      }
    }
  };
}

// Create and export store instance
export const dashboardStore = createDashboardStore();

// Export connection function for convenience
export const connectWebSocket = dashboardStore.connect;

// Export control functions for convenience
export const startGeneration = dashboardStore.startGeneration;
export const stopGeneration = dashboardStore.stopGeneration;
export const resetSystem = dashboardStore.resetSystem;
export const toggleAutoScroll = dashboardStore.toggleAutoScroll;
export const loadInitialData = dashboardStore.loadInitialData;