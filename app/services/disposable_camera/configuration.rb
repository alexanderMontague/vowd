module DisposableCamera
  class Configuration
    BUCKET_ENV_KEY = "BUCKET_NAME".freeze
    REGION_ENV_KEY = "AWS_REGION".freeze
    ENDPOINT_ENV_KEY = "AWS_ENDPOINT_URL_S3".freeze
    SSL_VERIFY_PEER_ENV_KEY = "AWS_SSL_VERIFY_PEER".freeze
    SSL_CA_BUNDLE_ENV_KEY = "AWS_SSL_CA_BUNDLE".freeze
    R2_ACCOUNT_ID_ENV_KEY = "R2_ACCOUNT_ID".freeze
    R2_DEFAULT_REGION = "auto".freeze
    STORAGE_BACKEND_ENV_KEY = "DISPOSABLE_CAMERA_STORAGE".freeze
    LOCAL_BACKEND = "local".freeze
    S3_BACKEND = "s3".freeze

    class << self
      # Uses the S3-compatible bucket whenever credentials are configured (or in
      # production). Force disk with DISPOSABLE_CAMERA_STORAGE=local, or the bucket
      # with DISPOSABLE_CAMERA_STORAGE=s3.
      def local_storage?
        case ENV[STORAGE_BACKEND_ENV_KEY].presence&.downcase
        when LOCAL_BACKEND then true
        when S3_BACKEND then false
        else
          return true if Rails.env.test?
          return false if Rails.env.production?

          !bucket_credentials?
        end
      end

      def bucket_credentials?
        ENV[BUCKET_ENV_KEY].present? &&
          ENV["AWS_ACCESS_KEY_ID"].present? &&
          ENV["AWS_SECRET_ACCESS_KEY"].present?
      end

      def bucket
        ENV.fetch(BUCKET_ENV_KEY)
      end

      def region
        ENV.fetch(REGION_ENV_KEY, R2_DEFAULT_REGION)
      end

      # Derived from the Cloudflare account id; AWS_ENDPOINT_URL_S3 overrides it.
      def endpoint
        ENV[ENDPOINT_ENV_KEY].presence || r2_endpoint
      end

      def force_path_style?
        ActiveModel::Type::Boolean.new.cast(ENV.fetch("FORCE_PATH_STYLE", nil))
      end

      def ssl_verify_peer?
        explicit_value = ENV[SSL_VERIFY_PEER_ENV_KEY]
        return ActiveModel::Type::Boolean.new.cast(explicit_value) if explicit_value.present?

        return false if endpoint.present? && !Rails.env.production?

        true
      end

      def ssl_ca_bundle
        ENV[SSL_CA_BUNDLE_ENV_KEY].presence
      end

      def aws_client_config
        config = { region: region }

        config[:access_key_id] = ENV["AWS_ACCESS_KEY_ID"] if ENV["AWS_ACCESS_KEY_ID"].present?
        if ENV["AWS_SECRET_ACCESS_KEY"].present?
          config[:secret_access_key] =
            ENV["AWS_SECRET_ACCESS_KEY"]
        end
        config[:endpoint] = endpoint if endpoint.present?
        config[:force_path_style] = true if force_path_style?
        config[:ssl_verify_peer] = ssl_verify_peer?
        config[:ssl_ca_bundle] = ssl_ca_bundle if ssl_ca_bundle.present?

        config
      end

      private

      def r2_endpoint
        account_id = ENV[R2_ACCOUNT_ID_ENV_KEY].presence
        return nil unless account_id

        "https://#{account_id}.r2.cloudflarestorage.com"
      end
    end
  end
end
