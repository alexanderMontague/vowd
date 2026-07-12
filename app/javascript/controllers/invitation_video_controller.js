import { Controller } from "@hotwired/stimulus";

const WHITE_FADE_MS = 700;

export default class extends Controller {
  static targets = [
    "video",
    "videoStage",
    "clickOverlay",
    "whiteCurtain",
    "content",
    "form",
  ];

  static values = {
    skipVideo: { type: Boolean, default: false },
  };

  connect() {
    this.revealed = false;
    this.started = false;
    this.boundOnEnded = null;

    if (this.skipVideoValue) {
      this.revealed = true;
      this.started = true;
      this.revealContentImmediately();
      return;
    }

    this.boundOnEnded = () => this.onEnded();
    this.videoTarget.addEventListener("ended", this.boundOnEnded);
  }

  disconnect() {
    if (this.boundOnEnded) {
      this.videoTarget.removeEventListener("ended", this.boundOnEnded);
    }
  }

  start() {
    if (this.started || this.revealed) return;
    this.started = true;
    this.clickOverlayTarget.classList.add(
      "opacity-0",
      "pointer-events-none",
      "invisible",
    );
    this.revealVideo();
    this.videoTarget.play().catch(() => {});
  }

  revealVideo() {
    this.videoTarget.classList.remove("opacity-0");
    this.videoTarget.classList.add("opacity-100");
  }

  onEnded() {
    this.fadeToContent();
  }

  revealContentImmediately() {
    this.clickOverlayTarget.classList.add(
      "opacity-0",
      "pointer-events-none",
      "invisible"
    );
    this.whiteCurtainTarget.classList.add("opacity-0");
    this.videoTarget.pause();
    this.videoStageTarget.classList.add("hidden");
    this.videoStageTarget.setAttribute("aria-hidden", "true");
    this.contentTarget.classList.remove("hidden");
    requestAnimationFrame(() => {
      this.contentTarget.classList.add("invitation-video-content--visible");
    });
  }

  fadeToContent() {
    if (this.revealed) return;
    this.revealed = true;
    this.whiteCurtainTarget.classList.remove("opacity-0");
    this.whiteCurtainTarget.classList.add("opacity-100");

    window.setTimeout(() => {
      this.videoStageTarget.classList.add("hidden");
      this.videoStageTarget.setAttribute("aria-hidden", "true");
      this.contentTarget.classList.remove("hidden");
      requestAnimationFrame(() => {
        this.contentTarget.classList.add("invitation-video-content--visible");
      });
    }, WHITE_FADE_MS);
  }

  showForm(event) {
    event.preventDefault();
    event.stopPropagation();
    if (!this.hasFormTarget) return;

    this.contentTarget.style.transition =
      "opacity 0.4s ease, transform 0.4s ease";
    this.contentTarget.style.opacity = "0";
    this.contentTarget.style.transform = "translateY(-20px)";

    window.setTimeout(() => {
      this.contentTarget.classList.add("hidden");
      this.formTarget.classList.remove("hidden");
      this.formTarget.scrollIntoView({ behavior: "smooth", block: "start" });
    }, 400);
  }
}
