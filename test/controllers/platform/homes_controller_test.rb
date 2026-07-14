require "test_helper"

module Platform
  class HomesControllerTest < ActionDispatch::IntegrationTest
    setup do
      host_platform!
    end

    test "landing page returns success" do
      get platform_root_path

      assert_response :success
    end
  end
end
