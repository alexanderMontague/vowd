require "test_helper"

module Public
  class SaveTheDateModeTest < ActionDispatch::IntegrationTest
    setup do
      @wedding = create_wedding
      host_wedding!(@wedding)
      @metadata = WeddingMetadata.create!(wedding_id: @wedding.id, key: "save_the_date_mode", value: "true")
    end

    teardown do
      @metadata&.destroy
    end

    test "save the date page remains accessible" do
      get public_save_the_date_path
      assert_response :success
    end

    test "calendar download remains accessible" do
      get public_calendar_ics_path(format: :ics)
      assert_response :success
    end

    test "home page redirects to save the date" do
      get root_path
      assert_redirected_to public_save_the_date_path
    end

    test "other public pages redirect to save the date" do
      get public_gallery_path
      assert_redirected_to public_save_the_date_path

      get public_faq_path
      assert_redirected_to public_save_the_date_path

      get public_rsvp_lookup_path
      assert_redirected_to public_save_the_date_path
    end

    test "dispo pages redirect to save the date" do
      get dispo_camera_path
      assert_redirected_to public_save_the_date_path
    end
  end
end
