# Testing Instructions for Svelte Dashboard Fixes

## 🚀 Start Servers

### 1. Start Phoenix Server
```bash
cd /home/server3/test2
mix deps.get
mix ecto.setup
mix phx.server
```

### 2. Start Svelte Dev Server (in new terminal)
```bash
cd /home/server3/test2/dashboard
npm run dev
```

## 🔍 Test Pages

### 1. Main Dashboard
- URL: `http://localhost:5173`
- Should show: Connection status, debug panel, invoice grid

### 2. Test Suite Page
- URL: `http://localhost:5173/test`
- Click buttons to test API and WebSocket connectivity

## 🐛 Debugging Issues

### Connection Error "unknown"
1. Check if Phoenix server is running on port 4000
2. Open test page at `http://localhost:5173/test`
3. Click "Test API Endpoints" to see specific errors
4. Check browser console for detailed error messages

### STOP Button Issues
1. Check the status display in dashboard
2. Look for "Running: true/false" and "Status: running/stopped"
3. Check browser console for debug messages from StatsStrip

### No Invoice Data
1. First test API endpoints work: `http://localhost:5173/test`
2. Try clicking START button manually
3. Check WebSocket connection in test page
4. Look at debug panel in bottom-right of main dashboard

## 🔧 Manual API Testing

If servers are running, test these URLs directly:

```bash
# Test if Phoenix is responding
curl http://localhost:4000/api/stats

# Test system status
curl http://localhost:4000/api/system/status

# Test starting generation
curl -X POST http://localhost:4000/api/control/start

# Test stopping generation  
curl -X POST http://localhost:4000/api/control/stop
```

## 📝 What to Look For

### In Main Dashboard (`http://localhost:5173`)
- ✅ Connection status indicator (top-right)
- ✅ Debug panel (bottom-right) - click to expand
- ✅ START button enabled, STOP button disabled initially
- ✅ Status showing "Running: false" and "Status: stopped"
- ✅ After clicking START: invoices should appear and scroll

### In Test Page (`http://localhost:5173/test`)
- ✅ API tests should all show "PASS" 
- ✅ WebSocket test should show "PASS"
- ✅ Control action tests should work

## 🚨 Common Issues & Solutions

### Issue: "Connection error: unknown"
**Solution**: Phoenix server not running or not accessible
- Check if `mix phx.server` is running
- Check if port 4000 is available
- Try the test page to get specific error details

### Issue: STOP button always disabled
**Solution**: System status not updating properly
- Check the status display shows correct values
- Look for console log messages about systemStatus updates
- Verify API endpoints work in test page

### Issue: No invoices appearing
**Solution**: WebSocket or generation not working
- Test WebSocket connection in test page
- Click START button and check for API errors
- Check debug panel for connection messages

### Issue: Data shows but doesn't update
**Solution**: Real-time updates not working
- WebSocket connection may be failing
- Check debug panel for connection status
- Try refreshing to reload initial data

## 📞 Next Steps

1. Run the test suite first to identify specific issues
2. Check browser console for detailed error messages  
3. Look at debug panel output for connection details
4. Test API endpoints manually if needed

The fixes include comprehensive debugging, so you should be able to see exactly what's happening with connections and data flow.