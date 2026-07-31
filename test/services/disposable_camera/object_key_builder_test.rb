require "test_helper"

module DisposableCamera
  class ObjectKeyBuilderTest < ActiveSupport::TestCase
    test "builds object keys with environment and wedding code" do
      object_key = ObjectKeyBuilder.build(wedding_code: "britt-and-alex", content_type: "image/jpeg")

      assert_match(
        %r{\Atest/britt-and-alex/photos/\d{8}-\d{6}-[0-9a-f]{16}\.jpg\z},
        object_key
      )
    end

    test "builds load-test object keys under lt/run_id" do
      object_key = ObjectKeyBuilder.build(
        wedding_code: "loadtest",
        content_type: "image/jpeg",
        load_test_run_id: "20260730T213000Z-1234"
      )

      assert_match(
        %r{\Atest/loadtest/photos/lt/20260730T213000Z-1234/\d{8}-\d{6}-[0-9a-f]{16}\.jpg\z},
        object_key
      )
    end

    test "ignores blank or invalid load_test_run_id" do
      blank_key = ObjectKeyBuilder.build(
        wedding_code: "loadtest",
        content_type: "image/png",
        load_test_run_id: " "
      )
      invalid_key = ObjectKeyBuilder.build(
        wedding_code: "loadtest",
        content_type: "image/png",
        load_test_run_id: "../evil"
      )

      assert_match(%r{\Atest/loadtest/photos/\d{8}-\d{6}-[0-9a-f]{16}\.png\z}, blank_key)
      assert_match(%r{\Atest/loadtest/photos/\d{8}-\d{6}-[0-9a-f]{16}\.png\z}, invalid_key)
    end

    test "sanitize_load_test_run_id accepts safe ids only" do
      assert_equal "run-1_abc", ObjectKeyBuilder.sanitize_load_test_run_id("run-1_abc")
      assert_nil ObjectKeyBuilder.sanitize_load_test_run_id("")
      assert_nil ObjectKeyBuilder.sanitize_load_test_run_id("has/slash")
      assert_nil ObjectKeyBuilder.sanitize_load_test_run_id("a" * 65)
    end

    test "raises for unsupported content type" do
      assert_raises(ArgumentError) do
        ObjectKeyBuilder.build(wedding_code: "britt-and-alex", content_type: "image/gif")
      end
    end
  end
end
