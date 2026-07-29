import { Controller } from "@hotwired/stimulus";

// Grain texture identical to the CSS `.retro-photo__grain` layer, so the
// exported download matches what's shown on screen.
const GRAIN_SVG =
  "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='180' height='180'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.9' numOctaves='4' stitchTiles='stitch'/%3E%3CfeColorMatrix type='saturate' values='0'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)'/%3E%3C/svg%3E";
const GRAIN_TILE = 140;
const JPEG_QUALITY = 0.92;

export default class extends Controller {
  static targets = ["overlay", "stage", "download"];

  connect() {
    this.boundHandleKeydown = this.handleKeydown.bind(this);
    this.currentIndex = -1;
  }

  disconnect() {
    document.removeEventListener("keydown", this.boundHandleKeydown);
  }

  get items() {
    return Array.from(this.element.querySelectorAll("[data-dispo-lightbox-item]"));
  }

  open(event) {
    const index = this.items.indexOf(event.currentTarget);
    if (index === -1) return;

    this.show(index);
    this.overlayTarget.classList.add("is-open");
    document.addEventListener("keydown", this.boundHandleKeydown);
  }

  next() {
    this.step(1);
  }

  prev() {
    this.step(-1);
  }

  step(delta) {
    const items = this.items;
    if (!items.length) return;
    this.show((this.currentIndex + delta + items.length) % items.length);
  }

  show(index) {
    const items = this.items;
    const item = items[index];
    if (!item) return;

    this.currentIndex = index;

    // Clone the styled figure so the enlarged view keeps the same layered filter
    // and per-photo variation (the inline CSS custom properties come along with
    // the copied style attribute).
    const figure = item.querySelector(".retro-photo");
    if (figure) this.stageTarget.replaceChildren(figure.cloneNode(true));

    if (this.hasDownloadTarget) {
      this.downloadTarget.href = item.dataset.dispoLightboxUrl || "#";
      const filename = item.dataset.dispoLightboxFilename;
      if (filename) this.downloadTarget.setAttribute("download", filename);
    }
  }

  // Exports the photo with the currently selected treatment baked in. The
  // original file is downloaded untouched (lossless); retro/bw are composited
  // onto a canvas from a same-origin copy so the download matches the preview.
  async download(event) {
    const style = this.element.dataset.photoStyle || "retro";
    const item = this.items[this.currentIndex];
    if (!item || style === "original") return;

    event.preventDefault();

    const rawUrl = item.dataset.dispoLightboxRaw;
    if (!rawUrl) return;

    try {
      const variation = this.readVariation(this.stageTarget.querySelector(".retro-photo"));
      const blob = await this.composeFilteredImage(rawUrl, style, variation);
      this.triggerDownload(blob, this.filteredFilename(item, style));
    } catch (error) {
      window.location.href = item.dataset.dispoLightboxUrl || rawUrl;
    }
  }

  close() {
    this.overlayTarget.classList.remove("is-open");
    this.stageTarget.replaceChildren();
    this.currentIndex = -1;
    document.removeEventListener("keydown", this.boundHandleKeydown);
  }

  closeOnBackdrop(event) {
    if (event.target === this.overlayTarget) this.close();
  }

  handleKeydown(event) {
    switch (event.key) {
      case "Escape":
        this.close();
        break;
      case "ArrowRight":
        this.next();
        break;
      case "ArrowLeft":
        this.prev();
        break;
    }
  }

  async composeFilteredImage(rawUrl, style, variation) {
    const image = await this.loadImage(rawUrl);
    const width = image.naturalWidth;
    const height = image.naturalHeight;

    const canvas = document.createElement("canvas");
    canvas.width = width;
    canvas.height = height;
    const context = canvas.getContext("2d");

    context.filter = this.filterString(style, variation);
    context.drawImage(image, 0, 0, width, height);
    context.filter = "none";

    const grainAlpha = style === "bw" ? variation.grainOpacity * 1.15 : variation.grainOpacity;
    await this.drawGrain(context, width, height, grainAlpha, variation);

    if (style === "retro") {
      this.drawFlashSpill(context, width, height, variation);
      this.drawCast(context, width, height);
    }

    this.drawVignette(context, width, height, variation);
    this.drawFrameEdge(context, width, height);

    return this.canvasToBlob(canvas);
  }

  filterString(style, v) {
    if (style === "bw") {
      return `grayscale(1) contrast(${(v.contrast + 0.08).toFixed(3)}) brightness(${v.brightness}) blur(${v.softness}px)`;
    }
    return `sepia(${v.sepia}) hue-rotate(${v.hue}deg) contrast(${v.contrast}) saturate(${v.saturate}) brightness(${v.brightness}) blur(${v.softness}px)`;
  }

  async drawGrain(context, width, height, alpha, v) {
    const pattern = await this.grainPattern(context);
    if (!pattern) return;

    const offsetX = (v.grainX / 100) * GRAIN_TILE;
    const offsetY = (v.grainY / 100) * GRAIN_TILE;

    context.save();
    context.globalCompositeOperation = "overlay";
    context.globalAlpha = alpha;
    context.translate(offsetX, offsetY);
    context.fillStyle = pattern;
    context.fillRect(-offsetX, -offsetY, width, height);
    context.restore();
  }

  drawFlashSpill(context, width, height, v) {
    const cx = (v.leakX / 100) * width;
    const cy = (v.leakY / 100) * height;
    const radius = this.farthestCorner(cx, cy, width, height);
    const warmHue = 42 + v.leakHue;
    const deepHue = 28 + v.leakHue;

    const gradient = context.createRadialGradient(cx, cy, 0, cx, cy, radius);
    gradient.addColorStop(0, `hsla(${warmHue}, 78%, 72%, ${v.leakOpacity})`);
    gradient.addColorStop(0.32, `hsla(${deepHue}, 70%, 58%, ${(v.leakOpacity * 0.45).toFixed(3)})`);
    gradient.addColorStop(0.68, `hsla(${deepHue}, 70%, 58%, 0)`);

    context.save();
    context.globalCompositeOperation = "soft-light";
    context.fillStyle = gradient;
    context.fillRect(0, 0, width, height);
    context.restore();
  }

  drawCast(context, width, height) {
    const gradient = context.createLinearGradient(0, 0, width * 0.35, height);
    gradient.addColorStop(0, "rgba(255, 214, 150, 0.18)");
    gradient.addColorStop(0.42, "rgba(255, 214, 150, 0)");
    gradient.addColorStop(1, "rgba(28, 48, 58, 0.22)");

    context.save();
    context.globalCompositeOperation = "soft-light";
    context.fillStyle = gradient;
    context.fillRect(0, 0, width, height);
    context.restore();
  }

  drawVignette(context, width, height, v) {
    const cx = width * 0.5;
    const cy = height * 0.46;
    const radius = Math.hypot(cx, cy);
    const gradient = context.createRadialGradient(cx, cy, 0, cx, cy, radius);
    gradient.addColorStop(0.28, "rgba(0, 0, 0, 0)");
    gradient.addColorStop(0.62, `rgba(0, 0, 0, ${(v.vignette * 0.35).toFixed(3)})`);
    gradient.addColorStop(1, `rgba(0, 0, 0, ${v.vignette})`);

    context.save();
    context.fillStyle = gradient;
    context.fillRect(0, 0, width, height);
    context.restore();
  }

  drawFrameEdge(context, width, height) {
    const inset = Math.max(2, Math.round(Math.min(width, height) * 0.004));

    context.save();
    context.strokeStyle = "rgba(8, 6, 4, 0.92)";
    context.lineWidth = inset * 2;
    context.strokeRect(inset, inset, width - inset * 2, height - inset * 2);

    const edge = context.createRadialGradient(
      width / 2,
      height / 2,
      Math.min(width, height) * 0.35,
      width / 2,
      height / 2,
      Math.hypot(width / 2, height / 2),
    );
    edge.addColorStop(0, "rgba(0, 0, 0, 0)");
    edge.addColorStop(0.7, "rgba(0, 0, 0, 0.28)");
    edge.addColorStop(1, "rgba(0, 0, 0, 0.55)");
    context.fillStyle = edge;
    context.fillRect(0, 0, width, height);
    context.restore();
  }

  farthestCorner(cx, cy, width, height) {
    return Math.hypot(Math.max(cx, width - cx), Math.max(cy, height - cy));
  }

  async grainPattern(context) {
    const image = await this.grainImage();
    const tile = document.createElement("canvas");
    tile.width = GRAIN_TILE;
    tile.height = GRAIN_TILE;
    tile.getContext("2d").drawImage(image, 0, 0, GRAIN_TILE, GRAIN_TILE);
    return context.createPattern(tile, "repeat");
  }

  grainImage() {
    this.grainImagePromise ||= this.loadImage(GRAIN_SVG);
    return this.grainImagePromise;
  }

  readVariation(figure) {
    const style = figure ? getComputedStyle(figure) : null;
    const num = (name, fallback) => {
      if (!style) return fallback;
      const value = parseFloat(style.getPropertyValue(name));
      return Number.isFinite(value) ? value : fallback;
    };

    return {
      sepia: num("--rp-sepia", 0.28),
      hue: num("--rp-hue", -6),
      contrast: num("--rp-contrast", 1.18),
      saturate: num("--rp-saturate", 0.82),
      brightness: num("--rp-brightness", 1.04),
      softness: num("--rp-softness", 0.45),
      grainOpacity: num("--rp-grain-opacity", 0.32),
      grainX: num("--rp-grain-x", 0),
      grainY: num("--rp-grain-y", 0),
      leakOpacity: num("--rp-leak-opacity", 0.22),
      leakX: num("--rp-leak-x", 48),
      leakY: num("--rp-leak-y", 38),
      leakHue: num("--rp-leak-hue", 0),
      vignette: num("--rp-vignette", 0.62),
    };
  }

  loadImage(src) {
    return new Promise((resolve, reject) => {
      const image = new Image();
      image.onload = () => resolve(image);
      image.onerror = () => reject(new Error("Image failed to load"));
      image.src = src;
    });
  }

  canvasToBlob(canvas) {
    return new Promise((resolve, reject) => {
      canvas.toBlob(
        (blob) => (blob ? resolve(blob) : reject(new Error("Canvas export failed"))),
        "image/jpeg",
        JPEG_QUALITY,
      );
    });
  }

  triggerDownload(blob, filename) {
    const url = URL.createObjectURL(blob);
    const anchor = document.createElement("a");
    anchor.href = url;
    anchor.download = filename;
    document.body.appendChild(anchor);
    anchor.click();
    anchor.remove();
    URL.revokeObjectURL(url);
  }

  filteredFilename(item, style) {
    const base = item.dataset.dispoLightboxFilename || "photo.jpg";
    return `${base.replace(/\.[^.]+$/, "")}-${style}.jpg`;
  }
}
