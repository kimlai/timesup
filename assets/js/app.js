// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import css from "../css/app.css";
import { Socket } from "phoenix";
import LiveSocket from "phoenix_live_view";
import Clipboard from "clipboard";

let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");
let liveSocket = new LiveSocket("/live", Socket, {
  params: { _csrf_token: csrfToken },
  hooks: {
    Blink: {
      updated() {
        event = this.el.dataset.event;
        if (event !== "") {
          console.log(event);
          this.pushEvent("blink_received");
          const overlay = document.createElement("div");
          overlay.className = "blink-overlay";
          overlay.classList.add(event);
          document.body.append(overlay);
          setTimeout(() => overlay.remove(), 500);
        }
      }
    }
  }
});

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)
window.liveSocket = liveSocket;

new Clipboard(".copy-share-url");
