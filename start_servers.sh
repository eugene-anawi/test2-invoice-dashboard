#!/bin/bash

echo "🚀 Starting Phoenix and Svelte servers for testing..."

# Navigate to Phoenix directory
cd /home/server3/test2

echo "📦 Installing Phoenix dependencies..."
mix deps.get

echo "🗄️ Setting up database..."
mix ecto.setup

echo "🌐 Starting Phoenix server on port 4000..."
mix phx.server &
PHOENIX_PID=$!

# Wait a moment for Phoenix to start
sleep 5

echo "🔧 Starting Svelte dev server on port 5173..."
cd dashboard
npm run dev &
SVELTE_PID=$!

echo "✅ Servers started!"
echo "   Phoenix: http://localhost:4000"
echo "   Svelte:  http://localhost:5173"
echo ""
echo "Phoenix PID: $PHOENIX_PID"
echo "Svelte PID:  $SVELTE_PID"
echo ""
echo "Press Ctrl+C to stop both servers"

# Wait for user interrupt
trap "echo '⏹️ Stopping servers...'; kill $PHOENIX_PID $SVELTE_PID; exit" INT
wait