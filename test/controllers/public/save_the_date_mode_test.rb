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

    test "calendar uses ceremony time when set" do
      @wedding.update!(ceremony_time: "5:30 PM", wedding_duration_hours: 4, timezone: "America/Los_Angeles")

      get public_calendar_ics_path(format: :ics)
      assert_response :success

      start_utc = @wedding.event_starts_at.utc.strftime("%Y%m%dT%H%M%SZ")
      end_utc = @wedding.event_ends_at.utc.strftime("%Y%m%dT%H%M%SZ")
      assert_includes response.body, "DTSTART:#{start_utc}"
      assert_includes response.body, "DTEND:#{end_utc}"
    end

    test "calendar defaults to four pm when ceremony time is blank" do
      @wedding.update!(ceremony_time: nil, wedding_duration_hours: 3, timezone: "America/Los_Angeles")

      get public_calendar_ics_path(format: :ics)
      assert_response :success

      assert_equal 16, @wedding.event_starts_at.hour
      start_utc = @wedding.event_starts_at.utc.strftime("%Y%m%dT%H%M%SZ")
      assert_includes response.body, "DTSTART:#{start_utc}"
    end

    test "home page redirects to save the date" do
      get root_path
      assert_redirected_to public_save_the_date_path
    end

    test "other public pages redirect to save the date" do
      get public_photos_path
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
