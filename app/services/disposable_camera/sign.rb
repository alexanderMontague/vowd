module DisposableCamera
  # The "scan me" sign a couple prints and puts up around the venue. Each sign is
  # unique to its wedding because it encodes that wedding's own public dispo URL,
  # which is how a scanned photo lands in the right gallery.
  class Sign
    include Rails.application.routes.url_helpers

    FILENAME_PREFIX = "dispo-qr".freeze
    # Wide enough that a full-page sign still lands near 300 DPI at the printer.
    DOWNLOAD_PNG_SIZE = 2000
    # Only sets the SVG's nominal size; the viewbox keeps it scalable either way.
    DOWNLOAD_MODULE_SIZE = 8

    def initialize(wedding:)
      @wedding = wedding
    end

    def url
      AppHost.wedding_public_url(@wedding, path: dispo_camera_path)
    end

    # Printed next to the code so a guest whose camera cannot scan can still type it.
    def display_url
      url.sub(%r{\Ahttps?://}, "")
    end

    def svg(module_size: DOWNLOAD_MODULE_SIZE)
      qr_code.svg(module_size: module_size)
    end

    def png(size: DOWNLOAD_PNG_SIZE)
      qr_code.png(size: size)
    end

    def filename(extension:)
      "#{FILENAME_PREFIX}-#{@wedding.id}.#{extension}"
    end

    private

    def qr_code
      @qr_code ||= QrCode.new(url)
    end
  end
end
