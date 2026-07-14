module Admin
  module Website
    class AssetsController < Admin::BaseController
      def create
        result = WeddingAssets::Uploader.call(
          wedding: current_wedding,
          purpose: params.require(:purpose),
          uploaded_file: params.require(:file)
        )

        render json: {
          object_key: result[:object_key],
          url: helpers.public_site_asset_path(object_key: result[:object_key])
        }, status: :created
      rescue ActionController::ParameterMissing, ArgumentError => e
        render json: { error: e.message }, status: :unprocessable_content
      rescue Aws::S3::Errors::ServiceError, Seahorse::Client::NetworkingError
        render json: { error: "Upload service is temporarily unavailable. Please try again." },
               status: :service_unavailable
      end
    end
  end
end
