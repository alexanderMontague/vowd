require "test_helper"

module Admin
  class DisposablePhotosControllerTest < ActionDispatch::IntegrationTest
    setup do
      @wedding = create_wedding
      @admin = create_admin_for(@wedding)

      household = Household.create!(wedding_id: @wedding.id, name: "Disposable Household")
      @guest = Guest.create!(
        wedding_id: @wedding.id,
        household: household,
        first_name: "Taylor",
        last_name: "Guest",
        email: "taylor-#{SecureRandom.hex(4)}@example.com"
      )

      @photo_one = create_photo!("test/#{SecureRandom.hex(8)}.jpg")
      @photo_two = create_photo!("test/#{SecureRandom.hex(8)}.jpg")
      @photo_three = create_photo!("test/#{SecureRandom.hex(8)}.jpg")
      @other_wedding_photo = DisposablePhoto.create!(
        wedding_id: "other-wedding",
        object_key: "test/#{SecureRandom.hex(8)}.jpg",
        content_type: "image/jpeg",
        byte_size: 1234,
        flash_enabled: false,
        captured_at: Time.current,
        source_ip: "127.0.0.1"
      )

      sign_in_admin(@admin)
    end

    test "shows disposable photos index for admin" do
      get admin_disposable_photos_path

      assert_response :success
      assert_includes response.body, "Gallery"
      assert_includes response.body, "Delete Selected"
      assert_includes response.body, @guest.full_name
    end

    test "deletes selected photos scoped to current wedding" do
      DisposableCamera::StorageClient.stub(:delete_objects!, true) do
        assert_difference("DisposablePhoto.count", -2) do
          delete destroy_selected_admin_disposable_photos_path, params: { photo_ids: [@photo_one.id, @photo_two.id] }
        end
      end

      assert_redirected_to admin_disposable_photos_path
      assert_not DisposablePhoto.exists?(@photo_one.id)
      assert_not DisposablePhoto.exists?(@photo_two.id)
      assert DisposablePhoto.exists?(@photo_three.id)
      assert DisposablePhoto.exists?(@other_wedding_photo.id)
    end

    test "deletes all photos only for current wedding" do
      DisposableCamera::StorageClient.stub(:delete_objects!, true) do
        assert_difference("DisposablePhoto.count", -3) do
          delete destroy_all_admin_disposable_photos_path
        end
      end

      assert_redirected_to admin_disposable_photos_path
      assert_not DisposablePhoto.exists?(@photo_one.id)
      assert_not DisposablePhoto.exists?(@photo_two.id)
      assert_not DisposablePhoto.exists?(@photo_three.id)
      assert DisposablePhoto.exists?(@other_wedding_photo.id)
    end

    private

    def create_photo!(object_key)
      DisposablePhoto.create!(
        wedding_id: @wedding.id,
        guest: @guest,
        object_key: object_key,
        content_type: "image/jpeg",
        byte_size: 2048,
        flash_enabled: true,
        captured_at: Time.current,
        source_ip: "127.0.0.1"
      )
    end
  end
end
