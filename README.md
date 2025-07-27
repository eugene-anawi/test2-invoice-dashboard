# Test2 - Real-time Invoice Dashboard

An Elixir/Phoenix/LiveView application demonstrating real-time e-commerce invoice streaming with actor processes and advanced OTP patterns.

## Features

🚀 **Real-time Invoice Generation**
- Generates invoices at 5/second for 5 minutes (1,500 total invoices)
- Random e-commerce data with realistic company names and amounts
- Automatic VAT calculation (15%) and totals

⚡ **Live Dashboard**
- Real-time statistics cards (count, total amount, VAT total, average)
- Auto-scrolling infinite grid displaying latest invoices
- Start/Stop controls with backlog processing
- Responsive design with sidebar navigation

🏗️ **Advanced Architecture**
- **OTP Actor Model**: Demonstrates Elixir's supervision trees and GenServer processes
- **Rate Limiting**: Producer generates at 5/sec, Display shows at 2/sec
- **Backlog Processing**: Continues displaying invoices after generation stops
- **Modular Design**: Domain-driven structure for easy maintenance

💾 **Database Integration**
- **PostgreSQL**: Primary data storage with optimized indexes
- **Redis**: High-performance caching for statistics
- **Ecto**: Database queries and migrations

🎭 **LiveView Real-time**
- **Phoenix PubSub**: Real-time communication between processes and UI
- **JavaScript Hooks**: Auto-scrolling and visual feedback
- **WebSocket**: Efficient real-time updates

## Architecture Overview

### OTP Supervision Tree
```
Application Supervisor
├── Database Supervisor
│   ├── Repo (PostgreSQL)
│   └── Redis Connection
├── Streaming Supervisor
│   ├── Coordinator (Master control)
│   ├── Producer (5/sec generation)
│   ├── Buffer (2/sec display)
│   ├── StatsAggregator (Real-time stats)
│   └── Broadcaster (PubSub management)
└── Web Supervisor
    ├── Phoenix Endpoint
    └── LiveView processes
```

### Data Flow
```
[START Button] 
    ↓
[Coordinator] starts system
    ↓
[Producer] generates invoices (5/sec) → [PostgreSQL]
    ↓
[Buffer] queues for display (2/sec)
    ↓
[PubSub] broadcasts to:
    ├── [StatsAggregator] → [Redis Cache] → [Stats Cards]
    └── [LiveView Grid] → Auto-scroll display
```

## Quick Start

### Prerequisites
- Elixir 1.14+ and Erlang/OTP 25+
- PostgreSQL 16 with `claude_dev` user (see setup below)
- Redis server (optional, graceful fallback)
- Node.js 18+ for assets

### Database Setup
```bash
# Create PostgreSQL user and database
sudo -u postgres psql -c "CREATE USER claude_dev WITH PASSWORD 'claude_dev_password' CREATEDB;"
createdb -U claude_dev -h localhost test2_dev

# Start Redis (optional)
redis-server
```

### Installation
```bash
# Clone and setup
cd test2
mix deps.get
mix ecto.migrate

# Install and build assets
cd assets && npm install && cd ..
mix assets.build

# Start the application
mix phx.server
```

Visit http://localhost:4000 to see the dashboard!

## Usage

### Dashboard Controls
1. **START Generation**: Begins invoice creation at 5/second for 5 minutes
2. **STOP Generation**: Stops creation but continues displaying backlog
3. **Reset System**: Clears all data and resets statistics

### Real-time Features
- **Statistics Cards**: Update live as invoices are processed
- **Invoice Grid**: Auto-scrolls with newest invoices at top
- **Visual Feedback**: Highlights and animations for new data
- **System Status**: Shows generation state and buffer sizes

### API Endpoints
```bash
# Get current statistics
curl http://localhost:4000/api/stats

# Start/stop generation
curl -X POST http://localhost:4000/api/control/start
curl -X POST http://localhost:4000/api/control/stop

# Get system status
curl http://localhost:4000/api/system/status

# Get recent invoices
curl http://localhost:4000/api/invoices?limit=20
```

## Technical Implementation

### Actor Process Design
Each major component runs as a separate GenServer process:

- **Coordinator**: Manages overall system state and coordinates other processes
- **Producer**: Generates invoices using `Faker` library for realistic data
- **Buffer**: Implements rate-limiting queue with configurable display speed
- **StatsAggregator**: Calculates statistics incrementally for performance
- **Broadcaster**: Manages Phoenix PubSub for real-time UI updates

### Rate Limiting Strategy
- **Generation Rate**: 5 invoices/second (200ms intervals)
- **Display Rate**: 2 invoices/second (500ms intervals)
- **Buffer Management**: Automatic queue processing with backlog handling
- **Memory Efficient**: Limits in-memory storage to prevent overflow

### Caching Strategy
- **Redis Primary**: Fast statistics access with automatic fallback
- **Database Fallback**: Recalculates from PostgreSQL if Redis unavailable
- **Incremental Updates**: Efficient stat updates without full recalculation
- **TTL Management**: Automatic cache expiration and refresh

### LiveView Integration
- **Real-time Subscriptions**: Automatic PubSub subscriptions for connected clients
- **Efficient Updates**: Only sends changed data to minimize bandwidth
- **JavaScript Hooks**: Custom client-side behavior for auto-scrolling
- **Responsive Design**: Works on desktop and mobile devices

## Development

### Testing
```bash
# Run tests
mix test

# Run with coverage
mix test --cover

# Test specific modules
mix test test/test2/streaming/
```

### Development Tools
```bash
# Interactive console
iex -S mix phx.server

# LiveDashboard (in development)
http://localhost:4000/dev/dashboard

# Database console
mix ecto.gen.migration add_feature
mix ecto.migrate
```

### Monitoring
The application includes comprehensive monitoring:

- **Telemetry**: Performance metrics for all components
- **Logging**: Structured logging with different levels
- **Health Checks**: Database and Redis connection monitoring
- **Process Supervision**: Automatic restart of failed components

## Configuration

### Environment Variables
```bash
DATABASE_URL=postgresql://claude_dev:claude_dev_password@localhost:5432/test2_dev
REDIS_URL=redis://localhost:6379
SECRET_KEY_BASE=your_secret_key_here
PHX_HOST=localhost
PORT=4000
```

### Customization
```elixir
# config/dev.exs - Adjust generation rates
config :test2, :generation,
  rate_ms: 200,           # 5/second
  display_rate_ms: 500,   # 2/second
  duration_minutes: 5     # Total runtime

# config/dev.exs - Redis settings
config :test2, :redis,
  host: "localhost",
  port: 6379,
  database: 0
```

## Production Deployment

### Docker Support
```dockerfile
# Dockerfile included for containerized deployment
FROM elixir:1.14-alpine AS builder
# ... (build configuration)
FROM alpine:3.16 AS runtime
# ... (runtime configuration)
```

### Performance Tuning
- **Database Connection Pooling**: Configured for high throughput
- **Redis Pipelining**: Batch operations for better performance
- **Efficient Queries**: Optimized database indexes and queries
- **Memory Management**: Bounded queues and automatic cleanup

## Architecture Benefits

This application showcases several key Elixir/OTP patterns:

1. **Fault Tolerance**: Crashed processes restart automatically without affecting others
2. **Scalability**: Each component can be scaled independently
3. **Real-time**: Efficient message passing between processes and UI
4. **Maintainability**: Clear separation of concerns and modular design
5. **Performance**: Optimized for high-throughput data processing

## License

MIT License - feel free to use this as a learning resource or starting point for your own real-time applications!

---

Built with ❤️ using Elixir, Phoenix, LiveView, PostgreSQL, and Redis.