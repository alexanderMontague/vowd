# frozen_string_literal: true

module QrHelper
  # Invitations use a softer stone ink to sit inside the printed design; signage
  # relies on QrCode's higher-contrast default instead.
  INVITATION_INK = "78716c"

  def qr_code_svg(url, color: INVITATION_INK, fill: QrCode::PAPER, **_options)
    QrCode.new(url, ink: color, paper: fill).svg.html_safe
  end
end
