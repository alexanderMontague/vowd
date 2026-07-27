require "test_helper"

module DisposableCamera
  class ConfigurationTest < ActiveSupport::TestCase
    test "derives r2 endpoint from account id when explicit endpoint is unset" do
      with_env(
        "AWS_ENDPOINT_URL_S3" => nil,
        "R2_ACCOUNT_ID" => "f36423bf0504a5661234304fb21c4447"
      ) do
        assert_equal(
          "https://f36423bf0504a5661234304fb21c4447.r2.cloudflarestorage.com",
          Configuration.endpoint
        )
      end
    end

    test "explicit endpoint overrides account id derivation" do
      with_env(
        "AWS_ENDPOINT_URL_S3" => "https://custom.example.com",
        "R2_ACCOUNT_ID" => "f36423bf0504a5661234304fb21c4447"
      ) do
        assert_equal "https://custom.example.com", Configuration.endpoint
      end
    end

    test "endpoint is nil when neither endpoint nor account id are set" do
      with_env(
        "AWS_ENDPOINT_URL_S3" => nil,
        "R2_ACCOUNT_ID" => nil
      ) do
        assert_nil Configuration.endpoint
      end
    end

    test "defaults region to auto for r2 compatibility" do
      with_env("AWS_REGION" => nil) do
        assert_equal "auto", Configuration.region
      end
    end

    test "uses local storage outside production when bucket credentials are absent" do
      with_env(
        "DISPOSABLE_CAMERA_STORAGE" => nil,
        "BUCKET_NAME" => nil,
        "AWS_ACCESS_KEY_ID" => nil,
        "AWS_SECRET_ACCESS_KEY" => nil
      ) do
        assert Configuration.local_storage?
      end
    end

    test "uses bucket storage outside production when credentials are configured" do
      with_env(
        "DISPOSABLE_CAMERA_STORAGE" => nil,
        "BUCKET_NAME" => "vowd",
        "AWS_ACCESS_KEY_ID" => "key",
        "AWS_SECRET_ACCESS_KEY" => "secret"
      ) do
        Rails.stub(:env, ActiveSupport::StringInquirer.new("development")) do
          assert_not Configuration.local_storage?
        end
      end
    end

    test "keeps test env on local disk even when credentials are configured" do
      with_env(
        "DISPOSABLE_CAMERA_STORAGE" => nil,
        "BUCKET_NAME" => "vowd",
        "AWS_ACCESS_KEY_ID" => "key",
        "AWS_SECRET_ACCESS_KEY" => "secret"
      ) do
        assert Configuration.local_storage?
      end
    end

    test "uses bucket storage in production by default" do
      with_env(
        "DISPOSABLE_CAMERA_STORAGE" => nil,
        "BUCKET_NAME" => nil,
        "AWS_ACCESS_KEY_ID" => nil,
        "AWS_SECRET_ACCESS_KEY" => nil
      ) do
        Rails.stub(:env, ActiveSupport::StringInquirer.new("production")) do
          assert_not Configuration.local_storage?
        end
      end
    end

    test "honors explicit local backend override" do
      with_env(
        "DISPOSABLE_CAMERA_STORAGE" => "local",
        "BUCKET_NAME" => "vowd",
        "AWS_ACCESS_KEY_ID" => "key",
        "AWS_SECRET_ACCESS_KEY" => "secret"
      ) do
        Rails.stub(:env, ActiveSupport::StringInquirer.new("production")) do
          assert Configuration.local_storage?
        end
      end
    end

    test "honors explicit s3 backend override" do
      with_env("DISPOSABLE_CAMERA_STORAGE" => "s3") do
        assert_not Configuration.local_storage?
      end
    end
  end
end
