require "aws-sdk-s3"

module DisposableCamera
  module Storage
    # Stores objects in an S3-compatible bucket (Cloudflare R2 in production).
    class S3Adapter < Adapter
      # S3 DeleteObjects allows up to 1000 keys per request.
      DELETE_BATCH_SIZE = 1000
      # The R2 S3 API endpoint is auth-only, so reads are served via short-lived
      # presigned URLs. SigV4 caps the expiry at 7 days; this is regenerated per render.
      PRESIGNED_URL_EXPIRES_IN = 1.day.to_i

      def upload!(io:, object_key:, content_type:)
        client.put_object(
          bucket: bucket,
          key: object_key,
          body: io,
          content_type: content_type
        )
      end

      def delete!(object_key:)
        client.delete_object(bucket: bucket, key: object_key)
      end

      def delete_objects!(object_keys:)
        keys = Array(object_keys).filter_map(&:presence)
        return if keys.empty?

        keys.each_slice(DELETE_BATCH_SIZE) do |batch|
          response = client.delete_objects(
            bucket: bucket,
            delete: { objects: batch.map { |key| { key: key } }, quiet: true }
          )
          log_delete_errors(response)
        end
      end

      def public_url_for(object_key)
        presigner.presigned_url(
          :get_object,
          bucket: bucket,
          key: object_key,
          expires_in: PRESIGNED_URL_EXPIRES_IN
        )
      end

      # Presigns a URL that forces the browser to download the object as an
      # attachment. Works cross-origin because the disposition is baked into the
      # signed response, so no bytes are proxied through the app.
      def download_url_for(object_key, filename: nil)
        presigner.presigned_url(
          :get_object,
          bucket: bucket,
          key: object_key,
          expires_in: PRESIGNED_URL_EXPIRES_IN,
          response_content_disposition: content_disposition(filename)
        )
      end

      def download_object(object_key)
        client.get_object(bucket: bucket, key: object_key).body
      end

      private

      def content_disposition(filename)
        sanitized = filename.to_s.gsub(/["\r\n]/, "").presence
        sanitized ? %(attachment; filename="#{sanitized}") : "attachment"
      end

      def client
        @client ||= Aws::S3::Client.new(**Configuration.aws_client_config)
      end

      def presigner
        @presigner ||= Aws::S3::Presigner.new(client: client)
      end

      def bucket
        Configuration.bucket
      end

      def log_delete_errors(response)
        response.errors.each do |err|
          Rails.logger.error(
            "Disposable photo bulk delete failed: key=#{err.key} code=#{err.code} message=#{err.message}"
          )
        end
      end
    end
  end
end
