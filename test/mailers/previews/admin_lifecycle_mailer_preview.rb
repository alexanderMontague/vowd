# frozen_string_literal: true

class AdminLifecycleMailerPreview < ActionMailer::Preview
  def welcome
    AdminLifecycleMailer.welcome(preview_admin)
  end

  def trial_expiring
    AdminLifecycleMailer.trial_expiring(preview_admin, days_left: 3)
  end

  def schedule_locking
    AdminLifecycleMailer.schedule_locking(preview_admin)
  end

  def wedding_congrats
    AdminLifecycleMailer.wedding_congrats(preview_admin)
  end

  private

  def preview_admin
    AdminUser.includes(:wedding).first || raise("Seed an admin user to preview lifecycle mailers")
  end
end
