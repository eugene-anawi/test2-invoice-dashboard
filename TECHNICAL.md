# Technical Documentation
# Real-Time E-Commerce Invoice Dashboard

**Version:** 1.0  
**Date:** July 27, 2025  
**Technology Stack:** Elixir, Phoenix, LiveView, PostgreSQL, Redis

---

## Layout System Documentation

### Dashboard on Port 4000 - Layout Architecture

Based on the code analysis, the dashboard on port 4000 uses a **custom CSS Grid and Flexbox layout system** with the following characteristics:

## 🏗️ **Layout System Used:**

### **1. CSS Grid + Flexbox Hybrid Layout**
- **Main Container**: Flexbox column layout (`flex-direction: column`)
- **Statistics Cards**: CSS Grid with 4 equal columns (`grid-template-columns: repeat(4, 1fr)`)
- **Invoice Data Grid**: CSS Grid with 11 fixed columns for invoice fields

### **2. Fixed Height Sectioned Layout**
```css
.dashboard-container {
  height: 800px;
  max-width: 1280px;
  display: flex;
  flex-direction: column;
}
```

**Layout Structure:**
- **Header**: 60px fixed height
- **Stats Strip**: 40px fixed height  
- **Totals Cards**: 80px fixed height
- **Invoice Grid**: 600px fixed height (remaining space)

### **3. Precise Layout Control**
- **Custom CSS Grid** for the invoice table (11-column layout)
- **Flexbox** for overall page structure and alignment
- **Fixed positioning** for control panel (floating top-center)
- **Responsive design** with media queries

### **4. Not Using Any Framework**
- **No Bootstrap, Tailwind utility classes, or other CSS frameworks**
- **Pure custom CSS** with hand-crafted grid systems
- **Phoenix LiveView** handles the dynamic content
- **Custom animations** for real-time updates

### **5. Layout Dimensions**
```
┌─────────────────────────────────────────┐
│ Control Panel (Fixed Top)               │ ← Fixed position
├─────────────────────────────────────────┤
│ Header (60px)                           │ ← Title + rates
├─────────────────────────────────────────┤
│ Stats Strip (40px)                      │ ← Generation info
├─────────────────────────────────────────┤
│ Totals Cards (80px)                     │ ← 4-column grid
├─────────────────────────────────────────┤
│ Invoice Grid (600px)                    │ ← 11-column table
└─────────────────────────────────────────┘
```

### **6. CSS Grid Specifications**

#### **Statistics Cards Grid:**
```css
.totals-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 16px;
}
```

#### **Invoice Data Grid:**
```css
.grid-header, .grid-row {
  display: grid;
  grid-template-columns: 80px 70px 120px 100px 80px 70px 80px 100px 100px 90px 70px;
  gap: 6px;
}
```

**Column Layout:**
1. **Invoice #** (80px) - Invoice number
2. **Date** (70px) - Invoice date
3. **Seller** (120px) - Seller company name
4. **Buyer** (100px) - Buyer company name
5. **Subtotal** (80px) - Pre-tax amount
6. **VAT** (70px) - 15% tax amount
7. **Total** (80px) - Final amount
8. **Export Country** (100px) - Exporting country
9. **Import Country** (100px) - Importing country
10. **Payment** (90px) - Payment mechanism
11. **Risk** (70px) - Risk profile (Green/Amber/Red)

### **7. Real-Time Animation System**

#### **New Invoice Entry Animation:**
```css
@keyframes streamInvoiceEntry {
  0% {
    background: linear-gradient(90deg, rgba(59, 130, 246, 0.15) 0%, rgba(59, 130, 246, 0.05) 100%);
    border-left: 3px solid rgb(59, 130, 246);
    transform: translateY(-5px);
    opacity: 0.8;
  }
  100% {
    background: transparent;
    border-left: none;
    transform: translateY(0);
    opacity: 1;
  }
}
```

#### **Highlight Animation:**
```css
@keyframes streamHighlight {
  0% {
    background: rgba(16, 185, 129, 0.1);
    box-shadow: 0 0 0 2px rgba(16, 185, 129, 0.2);
  }
  100% {
    background: transparent;
    box-shadow: none;
  }
}
```

### **8. Performance Optimizations**

#### **GPU Acceleration:**
```css
.invoice-stream {
  contain: layout style paint;
  will-change: scroll-position;
}

.invoice-stream .invoice-row {
  contain: layout style paint;
  transform: translateZ(0);
}
```

#### **LiveView Streams Integration:**
- Uses Phoenix LiveView streams for efficient DOM updates
- Limited to 100 visible invoices in DOM (`limit: 100`)
- Automatic scrolling with JavaScript hooks
- Real-time PubSub integration for instant updates

### **9. Responsive Design**

#### **Mobile/Tablet Breakpoint:**
```css
@media (max-width: 1000px) {
  .totals-grid {
    grid-template-columns: repeat(2, 1fr);
    grid-template-rows: repeat(2, 1fr);
  }
}
```

### **10. Component Architecture**

#### **Phoenix LiveView Template Structure:**
```elixir
def render(assigns) do
  ~H"""
  <div class="dashboard-container">
    <!-- Control Panel Fixed Top-Right -->
    <div class="control-panel">...</div>
    
    <!-- Section 1: Header (60px) -->
    <header class="header">...</header>
    
    <!-- Section 2: Statistics Strip (40px) -->
    <div class="stats-strip">...</div>
    
    <!-- Section 3: TOTALS Cards (80px) -->
    <div class="totals-container">...</div>
    
    <!-- Section 4: Invoice Grid (600px) -->
    <div class="invoice-section">...</div>
  </div>
  """
end
```

#### **Key Features:**
- **Custom CSS Grid system** - No external framework dependencies
- **Fixed-height sections** - Precise layout control for real-time streaming
- **Performance-optimized** - GPU acceleration and CSS containment
- **LiveView streams** - Efficient DOM manipulation for high-frequency updates
- **Responsive design** - Adapts to different screen sizes
- **Real-time animations** - Visual feedback for new data arrival

The layout is **highly optimized for real-time data streaming** with custom CSS animations for new invoice entries and uses **Phoenix LiveView streams** for efficient DOM updates without requiring complex JavaScript frameworks.

---

## Additional Technical Details

### Color Scheme
- **Background**: `#f8fafc` (Light gray)
- **Cards**: `#ffffff` (White)
- **Borders**: `#e2e8f0` (Light gray borders)
- **Text Primary**: `#1e293b` (Dark gray)
- **Text Secondary**: `#64748b` (Medium gray)
- **Success**: `#10b981` (Green)
- **Warning**: `#f59e0b` (Amber)
- **Error**: `#dc2626` (Red)

### Typography
- **Font Family**: `'Segoe UI', Tahoma, Geneva, Verdana, sans-serif`
- **Title**: 20px, 700 weight
- **Headers**: 16px, 600 weight
- **Body**: 12-14px, 400-500 weight
- **Small Text**: 10-11px, 400-500 weight

### Browser Compatibility
- **Modern browsers** with CSS Grid support
- **WebKit scrollbar** styling for Chrome/Safari
- **CSS containment** for performance optimization
- **Transform 3D** acceleration support required

This technical documentation provides a comprehensive overview of the layout system used in the real-time invoice dashboard, focusing on the custom CSS Grid and Flexbox implementation optimized for high-performance real-time data streaming.