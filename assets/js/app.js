// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Live Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"

// Invoice Grid Hook for auto-scrolling with LiveView Streams
let Hooks = {}

Hooks.InvoiceGrid = {
  mounted() {
    this.autoScroll = this.el.dataset.autoScroll === "true"
    console.log("InvoiceGrid mounted with streams, auto-scroll:", this.autoScroll)
    
    // Store reference to stream container
    this.streamContainer = this.el.querySelector('.invoice-stream')
    this.lastScrollHeight = this.el.scrollHeight
  },
  
  updated() {
    // Check if new content was added to the stream
    const currentScrollHeight = this.el.scrollHeight
    const streamContainer = this.streamContainer || this.el.querySelector('.invoice-stream')
    
    if (this.autoScroll && streamContainer) {
      // For streams, new items are added at the top, so scroll to top
      this.el.scrollTop = 0
      
      // Add smooth animation for new items
      const firstInvoice = streamContainer.querySelector('.invoice-row')
      if (firstInvoice && currentScrollHeight > this.lastScrollHeight) {
        firstInvoice.classList.add('new-invoice-stream')
        setTimeout(() => {
          firstInvoice.classList.remove('new-invoice-stream')
        }, 1500)
      }
    }
    
    this.lastScrollHeight = currentScrollHeight
  },
  
  destroyed() {
    console.log("InvoiceGrid with streams destroyed")
  }
}

// Handle toggle auto-scroll events
window.addEventListener("phx:toggle_auto_scroll", (e) => {
  const grid = document.getElementById("invoice-grid")
  if (grid && grid.phxHook) {
    grid.phxHook.autoScroll = e.detail.enabled
    console.log("Auto-scroll toggled:", e.detail.enabled)
  }
})

// Handle new invoice events with enhanced visual feedback for streams
window.addEventListener("phx:new_invoice", (e) => {
  console.log("New invoice received (streams):", e.detail.invoice.invoice_number)
  
  // For streams, the new invoice is already properly positioned
  // Just add a subtle visual indicator that a new invoice arrived
  setTimeout(() => {
    const streamContainer = document.querySelector(".invoice-stream")
    const firstRow = streamContainer?.querySelector(".invoice-row")
    if (firstRow) {
      // Add the new-invoice class for our CSS animation
      firstRow.classList.add("new-invoice-highlight")
      
      // Remove the class after animation completes
      setTimeout(() => {
        firstRow.classList.remove("new-invoice-highlight")
      }, 2000)
    }
  }, 50) // Reduced timeout since streams are more immediate
})

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: Hooks
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket