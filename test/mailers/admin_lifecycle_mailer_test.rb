require "test_helper"

class AdminLifecycleMailerTest < ActionMailer::TestCase
  setup do
    @wedding = create_wedding(
      title: "Britt & Alex",
      date: Date.new(2027, 7, 10),
      ceremony_time: "4:00 PM",
      timezone: "America/Toronto",
      trial_ends_at: 3.days.from_now
    )
    @admin = create_admin_for(@wedding, email: "britt@example.com")
  end

  test "welcome uses platform styling and admin CTA" do
    email = AdminLifecycleMailer.welcome(@admin)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal ["britt@example.com"], email.to
    assert_match(/Welcome to Vowd/, email.subject)
    assert_match(/Open your admin/, email.html_part.body.to_s)
    assert_match(/#2b5f52/, email.html_part.body.to_s)
    assert_match(/Vowd/, email.html_part.body.to_s)
  end

  test "schedule locking clarifies what stays editable" do
    email = AdminLifecycleMailer.schedule_locking(@admin)

    body = email.html_part.body.to_s
    assert_match(/lock soon/i, body)
    assert_match(/Theme, guest list, RSVPs/, body)
    assert_match(/Only schedule and venue/, body)
  end

  test "wedding congrats mentions forever hosting" do
    email = AdminLifecycleMailer.wedding_congrats(@admin)

    body = email.html_part.body.to_s
    assert_match(/Congratulations/, body)
    assert_match(/hosted forever/i, body)
  end
end
