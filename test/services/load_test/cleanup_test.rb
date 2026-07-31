require "test_helper"

module LoadTest
  class CleanupTest < ActiveSupport::TestCase
    setup do
      @wedding = create_wedding(id: "loadtest")
      @other = create_wedding(id: "other-wedding")
      @run_id = "20260730T213000Z-abcd"
      @lt_key = "test/loadtest/photos/lt/#{@run_id}/20260730-210000-aaaaaaaaaaaaaaaa.jpg"
      @normal_key = "test/loadtest/photos/20260730-210000-bbbbbbbbbbbbbbbb.jpg"

      @lt_photo = DisposablePhoto.create!(
        wedding_id: @wedding.id,
        object_key: @lt_key,
        content_type: "image/jpeg",
        byte_size: 100,
        flash_enabled: false,
        captured_at: Time.current,
        source_ip: "127.0.0.1"
      )
      @normal_photo = DisposablePhoto.create!(
        wedding_id: @wedding.id,
        object_key: @normal_key,
        content_type: "image/jpeg",
        byte_size: 100,
        flash_enabled: false,
        captured_at: Time.current,
        source_ip: "127.0.0.1"
      )
      @lt_signup = SaveTheDateSignup.create!(
        wedding_id: @wedding.id,
        name: "Load Tester",
        email: "lt-#{@run_id}-1@loadtest.vowd.invalid"
      )
      @real_signup = SaveTheDateSignup.create!(
        wedding_id: @wedding.id,
        name: "Real Guest",
        email: "guest@example.com"
      )
    end

    teardown do
      DisposablePhoto.where(wedding_id: [@wedding.id, @other.id]).delete_all
      SaveTheDateSignup.where(wedding_id: [@wedding.id, @other.id]).delete_all
    end

    test "dry run matches only tagged records" do
      with_env("LOADTEST_WEDDING_ID" => "loadtest") do
        result = Cleanup.call(wedding_id: "loadtest", run_id: @run_id, confirm: false)

        assert result.dry_run
        assert_equal 1, result.photos_matched
        assert_equal 1, result.signups_matched
        assert_equal 0, result.photos_deleted
        assert_equal [@lt_key], result.object_keys
        assert DisposablePhoto.exists?(@lt_photo.id)
        assert SaveTheDateSignup.exists?(@lt_signup.id)
      end
    end

    test "confirm deletes tagged photos and signups only" do
      deleted_keys = nil
      with_env("LOADTEST_WEDDING_ID" => "loadtest") do
        DisposableCamera::StorageClient.stub(:delete_objects!, ->(object_keys:) { deleted_keys = object_keys }) do
          result = Cleanup.call(wedding_id: "loadtest", run_id: @run_id, confirm: true)

          assert_equal 1, result.photos_deleted
          assert_equal 1, result.signups_deleted
        end
      end

      assert_equal [@lt_key], deleted_keys
      refute DisposablePhoto.exists?(@lt_photo.id)
      assert DisposablePhoto.exists?(@normal_photo.id)
      refute SaveTheDateSignup.exists?(@lt_signup.id)
      assert SaveTheDateSignup.exists?(@real_signup.id)
    end

    test "refuses cleanup when wedding does not match LOADTEST_WEDDING_ID" do
      with_env("LOADTEST_WEDDING_ID" => "loadtest") do
        error = assert_raises(ArgumentError) do
          Cleanup.call(wedding_id: "other-wedding", run_id: @run_id, confirm: true)
        end
        assert_match(/does not match LOADTEST_WEDDING_ID/, error.message)
      end
    end
  end
end
