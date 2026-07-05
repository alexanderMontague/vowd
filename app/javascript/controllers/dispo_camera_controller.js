import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "video",
    "canvas",
    "flashPop",
    "flashButton",
    "flipButton",
    "shutterButton",
    "status",
    "permissionGate",
    "permissionButton",
    "lockedGate",
  ];

  static values = {
    uploadUrl: String,
    closesAt: Number,
    forcedLocked: Boolean,
  };

  async connect() {
    this.flashEnabled = false;
    this.torchSupported = false;
    this.cameraReady = false;
    this.isUploading = false;
    this.isStartingCamera = false;
    this.lockTimer = null;
    this.facingMode = "environment";

    this.renderFlashButton();

    if (this.isCameraLocked()) {
      this.applyLock();
      return;
    }

    this.scheduleLockAt(this.closesAtValue);
    await this.initializeCameraAccess();
  }

  disconnect() {
    clearTimeout(this.lockTimer);
    this.stopCamera();
  }

  async toggleFlash() {
    if (!this.torchSupported || !this.track || !this.cameraReady) return;

    this.flashEnabled = !this.flashEnabled;

    try {
      await this.track.applyConstraints({
        advanced: [{ torch: this.flashEnabled }],
      });
      this.renderFlashButton();
    } catch (error) {
      this.flashEnabled = false;
      this.setStatus("Flash control is not available on this device.");
      this.renderFlashButton();
    }
  }

  async takePhoto() {
    if (!this.stream || !this.cameraReady) {
      this.setStatus("Camera is not ready yet.");
      return;
    }

    this.isUploading = true;
    this.updateShutterState();
    this.shutterButtonTarget.textContent = "Saving...";

    try {
      this.showFlashPop();
      const blob = await this.captureFrame();
      await this.uploadPhoto(blob);
      this.setStatus("Photo saved. Keep snapping.");
    } catch (error) {
      this.setStatus(error.message || "Could not upload photo.");
    } finally {
      this.isUploading = false;
      this.updateShutterState();
      this.shutterButtonTarget.textContent = "Capture";
    }
  }

  async requestCameraAccess() {
    await this.startCamera();
  }

  async initializeCameraAccess() {
    if (!navigator.mediaDevices?.getUserMedia) {
      this.hidePermissionGate();
      this.setStatus("Camera API is not available on this browser.");
      return;
    }

    if (!navigator.permissions?.query) {
      this.showPermissionGate();
      return;
    }

    try {
      const result = await navigator.permissions.query({ name: "camera" });

      if (result.state === "granted") {
        await this.startCamera();
      } else if (result.state === "denied") {
        this.showPermissionGate();
        this.setStatus("Camera access is blocked in browser settings.");
      } else {
        this.showPermissionGate();
      }
    } catch (_error) {
      this.showPermissionGate();
    }
  }

  async startCamera() {
    if (this.isStartingCamera || this.cameraReady) return;

    this.isStartingCamera = true;
    this.setPermissionButtonState(true, "Requesting...");

    try {
      this.stream = await navigator.mediaDevices.getUserMedia({
        audio: false,
        video: {
          facingMode: { ideal: this.facingMode },
          width: { ideal: 1920 },
          height: { ideal: 1080 },
        },
      });

      this.videoTarget.srcObject = this.stream;
      await this.videoTarget.play();
      this.track = this.stream.getVideoTracks()[0];
      this.cameraReady = true;
      this.applyMirror();
      this.setupTorchSupport();
      this.hidePermissionGate();
      this.updateShutterState();
      this.setStatus("Camera ready.");
      await this.checkFlipSupport();
    } catch (error) {
      this.cameraReady = false;
      this.stream = null;
      this.track = null;
      this.renderFlashButton();
      this.updateShutterState();
      this.showPermissionGate();
      this.setStatus(this.cameraErrorMessage(error));
    } finally {
      this.isStartingCamera = false;
      this.setPermissionButtonState(false, "Enable Camera");
    }
  }

  async flipCamera() {
    if (!this.cameraReady || this.isUploading) return;

    const prevFacing = this.facingMode;
    this.facingMode = prevFacing === "environment" ? "user" : "environment";

    this.stream?.getTracks().forEach((t) => t.stop());
    this.stream = null;
    this.track = null;
    this.cameraReady = false;
    this.torchSupported = false;
    this.flashEnabled = false;
    this.renderFlashButton();
    this.updateShutterState();

    try {
      this.stream = await navigator.mediaDevices.getUserMedia({
        audio: false,
        video: {
          facingMode: { ideal: this.facingMode },
          width: { ideal: 1920 },
          height: { ideal: 1080 },
        },
      });

      this.videoTarget.srcObject = this.stream;
      await this.videoTarget.play();
      this.track = this.stream.getVideoTracks()[0];
      this.cameraReady = true;
      this.applyMirror();
      this.setupTorchSupport();
      this.updateShutterState();
    } catch (error) {
      this.facingMode = prevFacing;
      this.setStatus("Could not switch camera.");
    }
  }

  applyMirror() {
    if (!this.hasVideoTarget) return;
    this.videoTarget.classList.toggle("dispo-viewfinder--mirrored", this.facingMode === "user");
  }

  async checkFlipSupport() {
    if (!this.hasFlipButtonTarget) return;

    try {
      const devices = await navigator.mediaDevices.enumerateDevices();
      const videoInputCount = devices.filter((d) => d.kind === "videoinput").length;
      this.flipButtonTarget.classList.toggle("hidden", videoInputCount < 2);
    } catch {
      // leave hidden
    }
  }

  stopCamera() {
    if (!this.stream) return;

    this.stream.getTracks().forEach((track) => track.stop());
    this.stream = null;
    this.track = null;
    this.cameraReady = false;
    this.renderFlashButton();
    this.updateShutterState();
  }

  setupTorchSupport() {
    if (!this.track || typeof this.track.getCapabilities !== "function") {
      this.torchSupported = false;
      this.renderFlashButton();
      return;
    }

    const capabilities = this.track.getCapabilities();
    this.torchSupported = Boolean(capabilities.torch);
    this.renderFlashButton();
  }

  renderFlashButton() {
    if (!this.flashButtonTarget) return;

    if (!this.cameraReady) {
      this.flashButtonTarget.textContent = "Off";
      this.flashButtonTarget.disabled = true;
      return;
    }

    if (!this.torchSupported) {
      this.flashButtonTarget.textContent = "";
      this.flashButtonTarget.disabled = true;
      return;
    }

    this.flashButtonTarget.disabled = false;
    this.flashButtonTarget.textContent = this.flashEnabled ? "On" : "Off";
  }

  captureFrame() {
    return new Promise((resolve, reject) => {
      const width = this.videoTarget.videoWidth;
      const height = this.videoTarget.videoHeight;

      if (!width || !height) {
        reject(new Error("Video feed is not ready."));
        return;
      }

      this.canvasTarget.width = width;
      this.canvasTarget.height = height;
      const context = this.canvasTarget.getContext("2d");

      if (this.facingMode === "user") {
        context.translate(width, 0);
        context.scale(-1, 1);
      }

      context.drawImage(this.videoTarget, 0, 0, width, height);
      this.canvasTarget.toBlob(
        (blob) => {
          if (blob) {
            resolve(blob);
          } else {
            reject(new Error("Failed to capture image."));
          }
        },
        "image/jpeg",
        0.9,
      );
    });
  }

  async uploadPhoto(blob) {
    const formData = new FormData();
    formData.append("photo", blob, `disposable-${Date.now()}.jpg`);
    formData.append("flash_enabled", String(this.flashEnabled));
    formData.append("captured_at", new Date().toISOString());

    const csrfToken = document.querySelector("meta[name='csrf-token']")?.content;
    const response = await fetch(this.uploadUrlValue, {
      method: "POST",
      headers: {
        "X-CSRF-Token": csrfToken || "",
      },
      body: formData,
      credentials: "same-origin",
    });

    if (!response.ok) {
      const contentType = response.headers.get("content-type") || "";
      if (contentType.includes("application/json")) {
        const errorPayload = await response.json().catch(() => ({}));
        throw new Error(errorPayload.error || "Upload failed.");
      }

      throw new Error("Upload failed.");
    }
  }

  showFlashPop() {
    this.flashPopTarget.classList.remove("hidden");
    this.flashPopTarget.classList.add("is-active");

    window.setTimeout(() => {
      this.flashPopTarget.classList.remove("is-active");
      this.flashPopTarget.classList.add("hidden");
    }, 180);
  }

  updateShutterState() {
    if (!this.hasShutterButtonTarget) return;
    const locked = this.isCameraLocked();
    this.shutterButtonTarget.disabled = locked || !this.cameraReady || this.isUploading;
  }

  isCameraLocked() {
    if (this.hasForcedLockedValue && this.forcedLockedValue) return true;
    return this.hasClosesAtValue && this.closesAtValue > 0 && Date.now() >= this.closesAtValue;
  }

  // Recursively reschedules if `closesAtMs` exceeds the JS setTimeout cap (~24.8 days),
  // so the lock fires correctly even for weddings far in the future.
  scheduleLockAt(closesAtMs) {
    if (!closesAtMs || closesAtMs <= 0) return;

    const MAX_TIMEOUT_MS = 0x7fffffff;
    const delay = closesAtMs - Date.now();

    if (delay <= 0) {
      this.applyLock();
      return;
    }

    this.lockTimer = setTimeout(
      () => this.scheduleLockAt(closesAtMs),
      Math.min(delay, MAX_TIMEOUT_MS),
    );
  }

  applyLock() {
    this.stopCamera();
    this.setStatus("The camera is now closed.");
    if (this.hasLockedGateTarget) this.lockedGateTarget.classList.remove("hidden");
    if (this.hasPermissionGateTarget) this.permissionGateTarget.classList.add("hidden");
    if (this.hasFlashButtonTarget) this.flashButtonTarget.disabled = true;
    if (this.hasFlipButtonTarget) this.flipButtonTarget.disabled = true;
    this.updateShutterState();
  }

  showPermissionGate() {
    if (!this.hasPermissionGateTarget) return;
    this.permissionGateTarget.classList.remove("hidden");
    this.updateShutterState();
  }

  hidePermissionGate() {
    if (!this.hasPermissionGateTarget) return;
    this.permissionGateTarget.classList.add("hidden");
    this.updateShutterState();
  }

  setPermissionButtonState(disabled, label) {
    if (!this.hasPermissionButtonTarget) return;
    this.permissionButtonTarget.disabled = disabled;
    this.permissionButtonTarget.textContent = label;
  }

  cameraErrorMessage(error) {
    if (!error?.name) return "Could not start camera. Try again.";

    if (error.name === "NotAllowedError") {
      return "Camera access denied. Allow access and try again.";
    }

    if (error.name === "NotFoundError") {
      return "No camera device detected on this browser.";
    }

    if (error.name === "NotReadableError") {
      return "Camera is in use by another app or tab.";
    }

    return "Could not start camera. Try again.";
  }

  setStatus(message) {
    this.statusTarget.textContent = message;
  }
}
