require "test_helper"

module DisposableCamera
  module Storage
    class S3AdapterTest < ActiveSupport::TestCase
      setup { @adapter = S3Adapter.new }

      test "builds a presigned read url for the object on the r2 endpoint" do
        with_env(
          "BUCKET_NAME" => "vowd",
          "AWS_REGION" => "auto",
          "R2_ACCOUNT_ID" => "f36423bf0504a5661234304fb21c4447",
          "AWS_ENDPOINT_URL_S3" => nil,
          "AWS_ACCESS_KEY_ID" => "test-key",
          "AWS_SECRET_ACCESS_KEY" => "test-secret"
        ) do
          object_key = "test/britt-and-alex/photos/example.jpg"
          uri = URI.parse(@adapter.public_url_for(object_key))
          query = URI.decode_www_form(uri.query).to_h

          assert_equal "vowd.f36423bf0504a5661234304fb21c4447.r2.cloudflarestorage.com", uri.host
          assert_equal "/#{object_key}", uri.path
          assert_equal "AWS4-HMAC-SHA256", query["X-Amz-Algorithm"]
          assert_equal S3Adapter::PRESIGNED_URL_EXPIRES_IN.to_s, query["X-Amz-Expires"]
          assert query["X-Amz-Signature"].present?
        end
      end

      test "uploads without an acl since r2 rejects object acls" do
        with_env("BUCKET_NAME" => "vowd") do
          captured = nil
          fake_client = Object.new
          fake_client.define_singleton_method(:put_object) { |params| captured = params }

          @adapter.stub(:client, fake_client) do
            @adapter.upload!(
              io: StringIO.new("data"),
              object_key: "test/britt-and-alex/photos/example.jpg",
              content_type: "image/jpeg"
            )
          end

          assert_equal "vowd", captured[:bucket]
          assert_equal "test/britt-and-alex/photos/example.jpg", captured[:key]
          assert_equal "image/jpeg", captured[:content_type]
          assert_not captured.key?(:acl)
        end
      end

      test "deletes object by key from configured bucket" do
        with_env("BUCKET_NAME" => "vowd") do
          fake_client = Minitest::Mock.new
          fake_client.expect(
            :delete_object,
            true,
            bucket: "vowd",
            key: "test/britt-and-alex/photos/example.jpg"
          )

          @adapter.stub(:client, fake_client) do
            @adapter.delete!(object_key: "test/britt-and-alex/photos/example.jpg")
          end

          fake_client.verify
        end
      end

      test "deletes multiple objects in batches via delete_objects" do
        with_env("BUCKET_NAME" => "vowd") do
          calls = []
          fake_client = Object.new
          fake_client.define_singleton_method(:delete_objects) do |params|
            calls << params
            Aws::S3::Types::DeleteObjectsOutput.new(errors: [])
          end

          @adapter.stub(:client, fake_client) do
            @adapter.delete_objects!(object_keys: %w[a.jpg b.jpg])
          end

          assert_equal 1, calls.size
          assert_equal "vowd", calls.first[:bucket]
          assert_equal %w[a.jpg b.jpg], calls.first[:delete][:objects].pluck(:key)
        end
      end

      test "skips delete_objects request when no keys are present" do
        fake_client = Object.new
        called = false
        fake_client.define_singleton_method(:delete_objects) { |_params| called = true }

        @adapter.stub(:client, fake_client) do
          @adapter.delete_objects!(object_keys: [nil, ""])
        end

        assert_not called
      end
    end
  end
end
