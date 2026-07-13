module DisposableCamera
  # Facade over the configured storage backend. Call sites stay backend-agnostic;
  # the concrete adapter (local disk vs S3-compatible bucket) is chosen from config.
  class StorageClient
    class << self
      delegate :upload!, :delete!, :delete_objects!, :public_url_for, :download_url_for, :download_object, to: :adapter

      def adapter
        @adapter ||= build_adapter
      end

      def reset_adapter!
        @adapter = nil
      end

      private

      def build_adapter
        if Configuration.local_storage?
          Storage::LocalAdapter.new
        else
          Storage::S3Adapter.new
        end
      end
    end
  end
end
