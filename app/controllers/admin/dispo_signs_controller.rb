module Admin
  class DispoSignsController < Admin::BaseController
    before_action :set_sign

    def show
      respond_to do |format|
        format.html
        format.svg { send_sign(@sign.svg, type: "image/svg+xml", extension: "svg") }
        format.png { send_sign(@sign.png, type: "image/png", extension: "png") }
      end
    end

    private

    def set_sign
      @sign = DisposableCamera::Sign.new(wedding: current_wedding)
    end

    def send_sign(data, type:, extension:)
      send_data data,
                type: type,
                filename: @sign.filename(extension: extension),
                disposition: "attachment"
    end
  end
end
