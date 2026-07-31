# frozen_string_literal: true

class PasswordResetMailerPreview < ActionMailer::Preview
  def reset
    admin = AdminUser.first || AdminUser.new(email: "preview@example.com")
    PasswordResetMailer.reset(admin)
  end
end
