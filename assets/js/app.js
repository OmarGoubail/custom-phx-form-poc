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
import "phoenix_html";
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import topbar from "../vendor/topbar";

// Define a debounce function
const debounce = (func, wait) => {
  let timeout;
  return function executedFunction(...args) {
    const later = () => {
      clearTimeout(timeout);
      func(...args);
    };
    clearTimeout(timeout);
    timeout = setTimeout(later, wait);
  };
};

// Define the Hooks object
let Hooks = {};

Hooks.InputValidation = {
  mounted() {
    this.isValidatedOnce = false;
    this.debounceTimer = null;

    const pushValidation = () => {
      // Push event with input name and value TO the component containing this element
      this.pushEventTo(this.el, "validate_input", {
        name: this.el.name,
        value: this.el.value,
      });
    };

    // Debounced version for input event after first blur
    this.debouncedPushValidation = debounce(pushValidation, 300); // 300ms debounce

    this.handleBlur = () => {
      // Only trigger immediate validation on the *first* blur
      // AND only if the input is not empty.
      if (!this.isValidatedOnce && this.el.value.trim() !== "") {
        this.isValidatedOnce = true;
        pushValidation();
      }
    };

    this.handleInput = () => {
      // If the field has been blurred at least once, validate with debounce
      if (this.isValidatedOnce) {
        this.debouncedPushValidation();
      }
    };

    // Add event listeners
    this.el.addEventListener("blur", this.handleBlur);
    this.el.addEventListener("input", this.handleInput);
  },

  destroyed() {
    // Clean up event listeners and timer when the element is removed
    this.el.removeEventListener("blur", this.handleBlur);
    this.el.removeEventListener("input", this.handleInput);
    if (this.debounceTimer) {
      clearTimeout(this.debounceTimer);
    }
  },
};

let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");
let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken },
  hooks: Hooks, // Register the Hooks object with LiveSocket
});

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" });
window.addEventListener("phx:page-loading-start", (_info) => topbar.show(300));
window.addEventListener("phx:page-loading-stop", (_info) => topbar.hide());

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;
