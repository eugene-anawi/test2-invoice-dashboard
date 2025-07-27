# Product Requirements Document (PRD)
# Real-Time E-Commerce Invoice Dashboard

**Version:** 1.0  
**Date:** July 27, 2025  
**Product:** test2 - Real-Time Invoice Streaming Dashboard  
**Technology Stack:** Elixir, Phoenix, LiveView, PostgreSQL, Redis

---

## 1. Executive Summary

### 1.1 Project Overview
The Real-Time E-Commerce Invoice Dashboard is an Elixir/Phoenix/LiveView application designed to demonstrate and test the actor process capabilities of Elixir and the real-time capabilities of Phoenix LiveView through a practical e-commerce invoice streaming system.

### 1.2 Primary Objectives
- **Technical Demonstration**: Showcase Elixir's OTP actor model and Phoenix LiveView real-time capabilities
- **Performance Testing**: Validate high-throughput data generation and real-time streaming
- **Modular Architecture**: Demonstrate maintainable, modular application design
- **User Experience**: Provide a coherent, user-friendly real-time data visualization interface

---

## 2. Product Vision & Goals

### 2.1 Vision Statement
Create a sophisticated real-time dashboard that showcases the power of Elixir's concurrent programming model while providing practical insights into e-commerce invoice data streaming and visualization.

### 2.2 Success Criteria
- Generate and display 1,500 invoices over 5 minutes (5 invoices/second)
- Maintain real-time UI responsiveness with 2 invoices/second display rate
- Demonstrate fault-tolerant actor process architecture
- Provide smooth, readable user interface with auto-scrolling capabilities
- Handle start/stop controls with proper backlog processing

---

## 3. Technical Requirements

### 3.1 Core Technology Stack
- **Backend**: Elixir with OTP supervision trees
- **Web Framework**: Phoenix with LiveView
- **Database**: PostgreSQL for persistent storage
- **Cache**: Redis for performance optimization
- **Frontend**: Phoenix LiveView with JavaScript hooks

### 3.2 Performance Requirements
- **Generation Rate**: 5 transactions per second for 5 minutes (1,500 total)
- **Display Rate**: Maximum 2 invoices per second for readability
- **Response Time**: Real-time updates with <100ms latency
- **Concurrency**: Support multiple concurrent user sessions
- **Reliability**: 99.9% uptime during generation periods

---

## 4. Functional Requirements

### 4.1 Data Generation Module
**Requirement ID**: FR-001  
**Priority**: High

**Description**: Generate random e-commerce invoice data continuously at specified rates.

**Specifications**:
- Generate invoices at 5 transactions per second
- Continue generation for exactly 5 minutes when started
- Store all invoices in PostgreSQL database
- Each invoice must contain:
  - Unique invoice number
  - Invoice date (timestamp)
  - Seller name (randomly generated)
  - Buyer name (randomly generated)
  - Subtotal amount
  - VAT amount (15% of subtotal)
  - Total amount (subtotal + VAT)

**Acceptance Criteria**:
- ✓ Exactly 1,500 invoices generated in 5-minute cycle
- ✓ All invoice data persisted to database
- ✓ No duplicate invoice numbers
- ✓ VAT calculations are accurate (15%)
- ✓ Generation can be started and stopped on command

### 4.2 Real-Time Dashboard Module
**Requirement ID**: FR-002  
**Priority**: High

**Description**: Display live statistics in dashboard cards showing aggregated invoice data.

**Specifications**:
- Display four main statistics cards:
  1. **Total Invoice Count**: Running count of all invoices
  2. **Total Invoice Amount**: Sum of all invoice totals
  3. **Total VAT Amount**: Sum of all VAT amounts
  4. **Average Invoice Amount**: Mean invoice value
- Update statistics in real-time as invoices are generated
- Statistics persist across start/stop cycles
- Use Redis caching for performance optimization

**Acceptance Criteria**:
- ✓ Statistics update within 100ms of invoice generation
- ✓ Calculations are mathematically accurate
- ✓ Cards remain visible at top of interface
- ✓ Statistics persist during system reset
- ✓ Redis cache improves performance measurably

### 4.3 Invoice Data Grid Module
**Requirement ID**: FR-003  
**Priority**: High

**Description**: Display invoices in an infinite-scroll data grid with automatic scrolling.

**Specifications**:
- Display invoices in tabular format with columns:
  - Invoice Number
  - Date/Time
  - Seller Name
  - Buyer Name
  - Subtotal
  - VAT Amount
  - Total Amount
- Show invoices at maximum 2 per second for readability
- Newest invoices appear at the top
- Automatic upward scrolling as new invoices are added
- Infinite scroll capability (no pagination limits)
- Proper spacing and padding from dashboard cards

**Acceptance Criteria**:
- ✓ Grid displays maximum 2 new invoices per second
- ✓ Automatic scroll keeps newest items visible
- ✓ All invoice data displayed accurately
- ✓ Grid remains readable during rapid updates
- ✓ No overlap with dashboard cards
- ✓ Smooth scrolling animation

### 4.4 Control Panel Module
**Requirement ID**: FR-004  
**Priority**: High

**Description**: Provide user controls for starting and stopping invoice generation.

**Specifications**:
- Side menu with two primary buttons:
  1. **START Button**: Initiates invoice generation
  2. **STOP Button**: Halts new invoice generation
- Generation does not start automatically on page load
- START button begins 5-minute generation cycle
- STOP button halts generation but allows backlog processing
- Visual indicators for system state (stopped/running/processing backlog)

**Acceptance Criteria**:
- ✓ System remains idle until START is clicked
- ✓ START button initiates generation immediately
- ✓ STOP button halts new generation
- ✓ Clear visual feedback for all system states
- ✓ Buttons are appropriately enabled/disabled

### 4.5 Backlog Processing Module
**Requirement ID**: FR-005  
**Priority**: High

**Description**: Handle invoice display backlog when generation is stopped.

**Specifications**:
- When STOP is clicked, cease generating new invoices
- Continue displaying invoices already in the pipeline
- Process all queued invoices at 2 per second rate
- Show "Processing backlog" indicator during drain period
- Complete backlog processing before returning to idle state

**Acceptance Criteria**:
- ✓ No new invoices generated after STOP clicked
- ✓ All queued invoices eventually displayed
- ✓ Backlog processing maintains 2/second display rate
- ✓ Clear indicator shows backlog processing status
- ✓ System returns to clean idle state when complete

---

## 5. Architecture Requirements

### 5.1 Modular Design Requirement
**Requirement ID**: AR-001  
**Priority**: High

**Description**: Implement modular architecture enabling independent component updates.

**Specifications**:
- Separate modules for distinct responsibilities:
  - Invoice domain logic
  - Streaming and rate management
  - Cache management
  - Web interface components
- Loose coupling between modules
- Clear module boundaries and APIs
- Independent testability of each module

**Acceptance Criteria**:
- ✓ Each module can be updated independently
- ✓ Module dependencies are minimal and well-defined
- ✓ Unit tests exist for each module
- ✓ Module interfaces are documented

### 5.2 Actor Process Architecture
**Requirement ID**: AR-002  
**Priority**: High

**Description**: Demonstrate Elixir's OTP actor model through process separation.

**Specifications**:
- Separate GenServer processes for:
  - Invoice generation coordination
  - Invoice production (5/second)
  - Display buffering (2/second)
  - Statistics aggregation
  - PubSub message broadcasting
- Proper supervision tree with fault tolerance
- Process isolation and message passing
- Graceful error handling and recovery

**Acceptance Criteria**:
- ✓ Each major function runs in separate process
- ✓ Process crashes don't affect other components
- ✓ Supervision tree restarts failed processes
- ✓ Message passing enables decoupled communication
- ✓ System remains stable under load

---

## 6. User Interface Requirements

### 6.1 Layout Specification
**Requirement ID**: UI-001  
**Priority**: High

**Description**: Define specific layout and visual hierarchy.

**Layout Structure**:
```
┌─────────────────────────────────────────┐
│ [🏁 START] [⏹️ STOP]     [System Status] │ ← Control Panel
├─────────────────────────────────────────┤
│ [📊 Count] [💰 Total] [🧾 VAT] [📈 Avg] │ ← Dashboard Cards  
├─────────────────────────────────────────┤
│ ┌─────────────────────────────────────┐ │
│ │ Invoice Data Grid                   │ │ ← Auto-scroll Grid
│ │ ├ [Latest Invoice]                  │ │
│ │ ├ [Previous Invoice]                │ │
│ │ ├ [...]                            │ │
│ └─────────────────────────────────────┘ │
└─────────────────────────────────────────┘
```

**Specifications**:
- Control panel fixed at top with clear visual hierarchy
- Dashboard cards in row format with consistent spacing
- Data grid with adequate padding from cards
- Responsive design for different screen sizes
- Professional color scheme and typography

**Acceptance Criteria**:
- ✓ No visual overlap between sections
- ✓ Consistent spacing and alignment
- ✓ Clear visual hierarchy and readability
- ✓ Professional appearance
- ✓ Responsive across device sizes

### 6.2 Real-Time Visual Feedback
**Requirement ID**: UI-002  
**Priority**: Medium

**Description**: Provide clear visual indicators for system state and data flow.

**Specifications**:
- System status indicator (Idle/Running/Stopping/Processing Backlog)
- Visual highlighting of new invoices as they appear
- Smooth auto-scroll animation
- Loading indicators during state transitions
- Color-coded buttons for different states

**Acceptance Criteria**:
- ✓ Users always understand current system state
- ✓ New data is visually highlighted
- ✓ Smooth, non-jarring animations
- ✓ Consistent visual language throughout

---

## 7. Data Requirements

### 7.1 Invoice Data Schema
**Entity**: Invoice  
**Storage**: PostgreSQL

**Fields**:
- `id`: Primary key (BIGSERIAL)
- `invoice_number`: Unique identifier (VARCHAR(50))
- `invoice_date`: Timestamp (TIMESTAMPTZ)
- `seller_name`: Company name (VARCHAR(255))
- `buyer_name`: Company name (VARCHAR(255))
- `subtotal`: Pre-tax amount (DECIMAL(12,2))
- `vat_amount`: 15% tax amount (DECIMAL(12,2))
- `total_amount`: Final amount (DECIMAL(12,2))
- `created_at`: Record creation time (TIMESTAMPTZ)

**Constraints**:
- Invoice numbers must be unique
- VAT amount must equal 15% of subtotal
- Total amount must equal subtotal + VAT
- All monetary amounts must be positive

### 7.2 Performance Data
**Cache Storage**: Redis

**Cached Elements**:
- Total invoice count
- Sum of all invoice amounts
- Sum of all VAT amounts
- Recent invoice buffer state
- System generation statistics

**Cache Strategy**:
- Increment counters on each invoice
- Use Redis pipelines for atomic updates
- Fallback to PostgreSQL if Redis unavailable
- Cache TTL for cleanup

---

## 8. Performance & Scalability

### 8.1 Performance Targets
- **Generation Rate**: Consistent 5 invoices/second
- **Display Rate**: Smooth 2 invoices/second display
- **Memory Usage**: <500MB during full generation cycle
- **Database Response**: <50ms average query time
- **UI Responsiveness**: <100ms update latency

### 8.2 Scalability Considerations
- Support for multiple concurrent user sessions
- Database connection pooling for efficiency
- Redis connection pooling
- Bounded queues to prevent memory bloat
- Efficient PubSub message broadcasting

---

## 9. Testing Strategy

### 9.1 Unit Testing
- Individual module testing
- GenServer process testing
- Database operation testing
- Cache operation testing

### 9.2 Integration Testing
- End-to-end workflow testing
- Real-time update verification
- Start/stop/backlog processing
- Multi-user session testing

### 9.3 Performance Testing
- Load testing with full generation rates
- Memory usage monitoring
- Database performance under load
- UI responsiveness under stress

---

## 10. Risk Assessment

### 10.1 Technical Risks
**High Risk**: Database connection issues under load  
**Mitigation**: Connection pooling, circuit breakers

**Medium Risk**: Redis cache unavailability  
**Mitigation**: Graceful fallback to PostgreSQL

**Medium Risk**: UI performance degradation  
**Mitigation**: Rate limiting, efficient rendering

### 10.2 Timeline Risks
**Risk**: Complex real-time synchronization  
**Mitigation**: Incremental development, thorough testing

---

## 11. Success Metrics

### 11.1 Functional Metrics
- ✓ 1,500 invoices generated in exactly 5 minutes
- ✓ All invoices displayed within backlog processing period
- ✓ 100% accurate VAT and total calculations
- ✓ Zero data loss during start/stop cycles

### 11.2 Performance Metrics
- ✓ <100ms latency for real-time updates
- ✓ Smooth UI performance throughout generation cycle
- ✓ Memory usage remains stable
- ✓ No process crashes or system failures

### 11.3 Architecture Metrics
- ✓ Independent module updates possible
- ✓ Process fault tolerance demonstrated
- ✓ Clear separation of concerns achieved
- ✓ Maintainable, readable codebase

---

## 12. Implementation Timeline

### Phase 1: Foundation (Week 1)
- Phoenix application setup
- Database schema and migrations
- Basic OTP supervision tree

### Phase 2: Core Logic (Week 2)
- Invoice generation module
- Actor process implementation
- Database integration

### Phase 3: Real-Time Features (Week 3)
- LiveView dashboard implementation
- PubSub messaging system
- Rate limiting and buffering

### Phase 4: UI & Polish (Week 4)
- User interface refinement
- Auto-scroll implementation
- Visual feedback and indicators

### Phase 5: Testing & Optimization (Week 5)
- Performance testing and optimization
- Comprehensive test suite
- Documentation completion

---

## 13. Appendices

### Appendix A: Technology Justification
- **Elixir**: Chosen for actor model demonstration and fault tolerance
- **Phoenix LiveView**: Enables real-time updates without complex JavaScript
- **PostgreSQL**: Reliable persistence with excellent Elixir integration
- **Redis**: High-performance caching for statistics aggregation

### Appendix B: Alternative Approaches Considered
- **GraphQL subscriptions**: Rejected due to added complexity
- **WebSocket channels**: Considered but LiveView provides better integration
- **In-memory storage**: Rejected due to persistence requirements

---

**Document Approval**:
- Technical Lead: [Pending]
- Product Owner: [Pending]  
- Architecture Review: [Pending]

---

*This PRD serves as the definitive specification for the Real-Time E-Commerce Invoice Dashboard project, ensuring all stakeholders understand the requirements, architecture, and success criteria for this Elixir/Phoenix demonstration application.*