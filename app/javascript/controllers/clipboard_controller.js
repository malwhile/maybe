import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["source", "iconDefault", "iconSuccess"];

  copy(event) {
    event.preventDefault();
    if (!this.sourceTarget) {
      console.error("Clipboard: source target not found");
      return;
    }

    const text = this.sourceTarget.textContent;
    if (!text) {
      console.error("Clipboard: source target has no text content");
      return;
    }

    navigator.clipboard
      .writeText(text)
      .then(() => {
        console.log("Clipboard: Successfully copied text");
        this.showSuccess();
      })
      .catch((error) => {
        console.error("Clipboard: Failed to copy text:", error);
        alert("Failed to copy to clipboard. This may be a browser permission issue.\n\nError: " + error.message);
      });
  }

  showSuccess() {
    if (this.hasIconDefaultTarget && this.hasIconSuccessTarget) {
      this.iconDefaultTarget.classList.add("hidden");
      this.iconSuccessTarget.classList.remove("hidden");
      setTimeout(() => {
        this.iconDefaultTarget.classList.remove("hidden");
        this.iconSuccessTarget.classList.add("hidden");
      }, 3000);
    }
  }
}
