# Single source of QR rendering for every printed artifact (invitations, venue
# signs) so codes stay visually consistent and scannable.
class QrCode
  # Level :m tolerates ~15% damage, enough for cardstock and laminated signage.
  ERROR_CORRECTION_LEVEL = :m
  INK = "1c1917".freeze
  PAPER = "fafaf9".freeze
  SVG_MODULE_SIZE = 3
  PNG_SIZE = 2000
  # The spec's minimum clear margin. Scanners need it to lock onto the code, and
  # it must scale with module_size because rqrcode's SVG offset is absolute.
  QUIET_ZONE_MODULES = 4

  def initialize(url, ink: INK, paper: PAPER)
    @url = url
    @ink = ink
    @paper = paper
  end

  def svg(module_size: SVG_MODULE_SIZE)
    code.as_svg(
      module_size: module_size,
      standalone: true,
      viewbox: true,
      color: @ink,
      fill: @paper,
      offset: module_size * QUIET_ZONE_MODULES,
      shape_rendering: "geometricPrecision"
    )
  end

  def png(size: PNG_SIZE)
    code.as_png(
      size: size,
      border_modules: QUIET_ZONE_MODULES,
      color: "##{@ink}",
      fill: "##{@paper}"
    ).to_blob
  end

  private

  def code
    @code ||= RQRCode::QRCode.new(@url, level: ERROR_CORRECTION_LEVEL)
  end
end
