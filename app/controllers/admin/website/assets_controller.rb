module Admin
  module Website
    class AssetsController < Admin::BaseController
      before_action :set_asset, only: %i[update destroy]

      # Every upload joins the wedding's photo library, whichever widget started it.
      def create
        @asset = add_to_library(upload!)
        assign_envelope!(@asset) if @asset.video?

        respond_to do |format|
          format.turbo_stream { render status: :created }
          format.json { render json: asset_payload(@asset), status: :created }
        end
      rescue ActionController::ParameterMissing, ArgumentError => e
        render json: { error: e.message }, status: :unprocessable_content
      rescue Aws::S3::Errors::ServiceError, Seahorse::Client::NetworkingError
        render json: { error: "Upload service is temporarily unavailable. Please try again." },
               status: :service_unavailable
      end

      def update
        @asset.update!(asset_params)
        render json: asset_payload(@asset)
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.record.errors.full_messages.to_sentence }, status: :unprocessable_content
      end

      def destroy
        clear_envelope_placement! if envelope_asset?(@asset)
        @asset.destroy!

        respond_to do |format|
          format.turbo_stream
          format.json { head :no_content }
        end
      end

      private

      def upload!
        WeddingAssets::Uploader.call(
          wedding: current_wedding,
          purpose: params.require(:purpose),
          uploaded_file: params.require(:file)
        )
      end

      def add_to_library(upload)
        current_wedding.wedding_assets.create!(
          object_key: upload[:object_key],
          content_type: upload[:content_type],
          byte_size: upload[:byte_size],
          position: next_position
        )
      end

      def assign_envelope!(asset)
        previous = current_wedding.placement("invitation_envelope")
        placements = current_wedding.placements.merge("invitation_envelope" => [asset.id])
        current_wedding.update!(placements: placements)
        return if previous.blank? || previous.id == asset.id

        previous.destroy!
      end

      def clear_envelope_placement!
        placements = current_wedding.placements.except("invitation_envelope")
        current_wedding.update!(placements: placements)
      end

      def envelope_asset?(asset)
        current_wedding.placement("invitation_envelope")&.id == asset.id
      end

      def set_asset
        @asset = current_wedding.wedding_assets.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Photo not found." }, status: :not_found
      end

      def asset_params
        params.require(:wedding_asset).permit(:alt, :caption, :position)
      end

      def asset_payload(asset)
        {
          id: asset.id,
          object_key: asset.object_key,
          alt: asset.alt.to_s,
          url: helpers.wedding_asset_url(asset),
          thumbnail_url: helpers.wedding_asset_thumbnail_url(asset)
        }
      end

      def next_position
        (current_wedding.wedding_assets.maximum(:position) || -1) + 1
      end
    end
  end
end
