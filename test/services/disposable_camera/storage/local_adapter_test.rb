require "test_helper"

module DisposableCamera
  module Storage
    class LocalAdapterTest < ActiveSupport::TestCase
      setup { @adapter = LocalAdapter.new }

      teardown do
        FileUtils.rm_rf(Rails.public_path.join(LocalAdapter::PUBLIC_SUBPATH, "test"))
      end

      test "writes the uploaded bytes to the public uploads directory" do
        object_key = "test/#{SecureRandom.hex(8)}/photos/example.jpg"

        @adapter.upload!(io: StringIO.new("photo-bytes"), object_key: object_key, content_type: "image/jpeg")

        assert_equal "photo-bytes", File.read(absolute_path(object_key))
      end

      test "builds a root-relative public url served by the static file server" do
        object_key = "test/wedding/photos/example.jpg"

        assert_equal(
          "/#{LocalAdapter::PUBLIC_SUBPATH}/#{object_key}",
          @adapter.public_url_for(object_key)
        )
      end

      test "download url matches the display url since files are served same-origin" do
        object_key = "test/wedding/photos/example.jpg"

        assert_equal(
          @adapter.public_url_for(object_key),
          @adapter.download_url_for(object_key, filename: "anything.jpg")
        )
      end

      test "download_object returns a readable io of the stored bytes" do
        object_key = "test/#{SecureRandom.hex(8)}/photos/example.jpg"
        @adapter.upload!(io: StringIO.new("photo-bytes"), object_key: object_key, content_type: "image/jpeg")

        io = @adapter.download_object(object_key)

        assert_equal "photo-bytes", io.read
      ensure
        io&.close
      end

      test "deletes a stored object" do
        object_key = "test/#{SecureRandom.hex(8)}/photos/example.jpg"
        @adapter.upload!(io: StringIO.new("x"), object_key: object_key, content_type: "image/jpeg")

        @adapter.delete!(object_key: object_key)

        assert_not File.exist?(absolute_path(object_key))
      end

      test "delete is a no-op when the object is missing" do
        assert_nothing_raised do
          @adapter.delete!(object_key: "test/missing/photos/none.jpg")
        end
      end

      test "deletes multiple objects" do
        keys = Array.new(2) { "test/#{SecureRandom.hex(8)}/photos/example.jpg" }
        keys.each { |key| @adapter.upload!(io: StringIO.new("x"), object_key: key, content_type: "image/jpeg") }

        @adapter.delete_objects!(object_keys: keys)

        assert(keys.none? { |key| File.exist?(absolute_path(key)) })
      end

      test "rejects object keys attempting path traversal" do
        assert_raises(ArgumentError) do
          @adapter.upload!(io: StringIO.new("x"), object_key: "test/../../etc/passwd", content_type: "image/jpeg")
        end
      end

      private

      def absolute_path(object_key)
        Rails.public_path.join(LocalAdapter::PUBLIC_SUBPATH, object_key)
      end
    end
  end
end
