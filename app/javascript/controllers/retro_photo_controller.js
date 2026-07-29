import { Controller } from "@hotwired/stimulus";

// Derives a stable, per-photo disposable-film treatment from a seed (the photo
// id) and exposes it as CSS custom properties. The variation is deterministic —
// the same photo always gets the same grain drift, flash spill, vignette, soft
// focus and colour grade — so the look never flickers between renders while
// still differing photo-to-photo. The original image bytes are never touched;
// this only feeds the CSS filter layers.
export default class extends Controller {
  static values = { seed: String };

  connect() {
    this.applyVariation();
  }

  applyVariation() {
    const seed = this.seedValue || this.element.id || "vowd-photo";
    const random = this.buildRandom(this.hashSeed(seed));
    const between = (min, max) => min + (max - min) * random();

    const properties = {
      "--rp-leak-x": `${between(35, 65).toFixed(1)}%`,
      "--rp-leak-y": `${between(28, 52).toFixed(1)}%`,
      "--rp-leak-hue": `${between(-12, 18).toFixed(0)}deg`,
      "--rp-leak-opacity": between(0.14, 0.28).toFixed(2),
      "--rp-grain-x": `${between(0, 100).toFixed(0)}%`,
      "--rp-grain-y": `${between(0, 100).toFixed(0)}%`,
      "--rp-grain-opacity": between(0.26, 0.4).toFixed(2),
      "--rp-vignette": between(0.52, 0.72).toFixed(2),
      "--rp-tilt": `${between(-0.8, 0.8).toFixed(2)}deg`,
      "--rp-sepia": between(0.22, 0.36).toFixed(2),
      "--rp-hue": `${between(-10, 2).toFixed(0)}deg`,
      "--rp-contrast": between(1.12, 1.26).toFixed(2),
      "--rp-saturate": between(0.72, 0.9).toFixed(2),
      "--rp-brightness": between(1.0, 1.08).toFixed(2),
      "--rp-softness": `${between(0.35, 0.55).toFixed(2)}px`,
    };

    for (const [name, value] of Object.entries(properties)) {
      this.element.style.setProperty(name, value);
    }
  }

  // FNV-1a → 32-bit unsigned seed.
  hashSeed(text) {
    let hash = 0x811c9dc5;
    for (let index = 0; index < text.length; index++) {
      hash ^= text.charCodeAt(index);
      hash = Math.imul(hash, 0x01000193);
    }
    return hash >>> 0;
  }

  // Mulberry32: fast deterministic PRNG seeded from a single 32-bit integer.
  buildRandom(seed) {
    let state = seed >>> 0;
    return () => {
      state = (state + 0x6d2b79f5) | 0;
      let t = Math.imul(state ^ (state >>> 15), 1 | state);
      t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
      return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
    };
  }
}
