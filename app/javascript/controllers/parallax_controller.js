import { Controller } from "@hotwired/stimulus"

const DESKTOP_QUERY = "(min-width: 1024px)"
const REDUCED_MOTION_QUERY = "(prefers-reduced-motion: reduce)"
const DEFAULT_SPEED = 0.12
// Cap the drift so a layer can never wander far from where it was authored.
const MAX_SHIFT_RATIO = 0.15
// Start tracking a layer before it scrolls in, so it is already in the right place.
const CULL_MARGIN = "35% 0px"
// Layers read this back out of CSS, so a layer can compose the drift with its own
// authored rotation or offset instead of having its transform overwritten.
const SHIFT_PROPERTY = "--parallax-shift"

// Drifts decorative layers against the scroll position. Skipped entirely on narrow
// screens and when the visitor asks for reduced motion.
//
// One rAF loop drives every layer, and offscreen layers are culled by an
// IntersectionObserver, so a page can carry a lot of ornament without the scroll
// handler growing with it.
export default class extends Controller {
  static targets = ["layer"]

  connect() {
    this.frame = null
    this.shifts = new WeakMap()
    this.onscreen = new Set()
    this.desktop = window.matchMedia(DESKTOP_QUERY)
    this.reducedMotion = window.matchMedia(REDUCED_MOTION_QUERY)

    this.schedule = this.schedule.bind(this)
    this.evaluate = this.evaluate.bind(this)

    window.addEventListener("scroll", this.schedule, { passive: true })
    window.addEventListener("resize", this.schedule, { passive: true })
    this.desktop.addEventListener("change", this.evaluate)
    this.reducedMotion.addEventListener("change", this.evaluate)

    // The save the date content stays hidden until the invitation video ends, so the
    // element has no size at connect. Reacting to its size settles the first frame.
    this.resizeObserver = new ResizeObserver(this.schedule)
    this.resizeObserver.observe(this.element)

    this.visibilityObserver = new IntersectionObserver(
      (entries) => this.trackVisibility(entries),
      { rootMargin: CULL_MARGIN }
    )
    this.layerTargets.forEach((layer) => this.visibilityObserver.observe(layer))

    this.evaluate()
  }

  disconnect() {
    window.removeEventListener("scroll", this.schedule)
    window.removeEventListener("resize", this.schedule)
    this.desktop.removeEventListener("change", this.evaluate)
    this.reducedMotion.removeEventListener("change", this.evaluate)
    this.resizeObserver?.disconnect()
    this.visibilityObserver?.disconnect()
    if (this.frame) cancelAnimationFrame(this.frame)
    this.onscreen.clear()
    this.reset()
  }

  // Layers can arrive after connect (a theme partial rendered into a Turbo frame).
  layerTargetConnected(layer) {
    this.visibilityObserver?.observe(layer)
  }

  layerTargetDisconnected(layer) {
    this.visibilityObserver?.unobserve(layer)
    this.onscreen.delete(layer)
  }

  trackVisibility(entries) {
    entries.forEach((entry) => {
      if (entry.isIntersecting) this.onscreen.add(entry.target)
      else this.onscreen.delete(entry.target)
    })

    this.schedule()
  }

  evaluate() {
    if (this.enabled) this.schedule()
    else this.reset()
  }

  schedule() {
    if (!this.enabled || this.frame) return

    this.frame = requestAnimationFrame(() => {
      this.frame = null
      this.render()
    })
  }

  // Each layer drifts around the point where it crosses the middle of the viewport, so
  // the offset is measured from its own untransformed position rather than the group's.
  render() {
    const viewportCentre = window.innerHeight / 2
    const maxShift = window.innerHeight * MAX_SHIFT_RATIO

    this.onscreen.forEach((layer) => {
      const rect = layer.getBoundingClientRect()
      if (rect.height === 0) return

      const applied = this.shifts.get(layer) || 0
      const centre = rect.top + rect.height / 2 - applied
      const speed = Number(layer.dataset.parallaxSpeed || DEFAULT_SPEED)
      const shift = clamp((viewportCentre - centre) * speed, -maxShift, maxShift)

      this.shifts.set(layer, shift)
      layer.style.setProperty(SHIFT_PROPERTY, `${shift.toFixed(2)}px`)
    })
  }

  reset() {
    this.layerTargets.forEach((layer) => {
      this.shifts.delete(layer)
      layer.style.removeProperty(SHIFT_PROPERTY)
    })
  }

  get enabled() {
    return this.desktop.matches && !this.reducedMotion.matches
  }
}

function clamp(value, min, max) {
  return Math.min(Math.max(value, min), max)
}
