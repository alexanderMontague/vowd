class AdminLifecyclePipelineJob < ApplicationJob
  queue_as :default

  def perform(reference_time: nil)
    current_time = normalize_time(reference_time)

    Wedding.includes(:admin_user).find_each do |wedding|
      process_wedding(wedding, current_time)
    end
  end

  private

  def process_wedding(wedding, current_time)
    tz = ActiveSupport::TimeZone[wedding.timezone] || Time.zone
    local_date = current_time.in_time_zone(tz).to_date

    enqueue_trial_reminders(wedding, local_date)
    enqueue_schedule_locking(wedding, local_date)
    enqueue_wedding_congrats(wedding, local_date)
  end

  def enqueue_trial_reminders(wedding, local_date)
    return unless Billing.enabled?
    return unless wedding.trial_active?
    return if wedding.trial_ends_at.blank?

    trial_date = wedding.trial_ends_at.in_time_zone(wedding.timezone).to_date

    if trial_date == local_date + 3.days
      AdminLifecycle::Sender.enqueue!(wedding: wedding, kind: "trial_expiring_3d")
    elsif trial_date == local_date + 1.day
      AdminLifecycle::Sender.enqueue!(wedding: wedding, kind: "trial_expiring_1d")
    end
  end

  def enqueue_schedule_locking(wedding, local_date)
    start = wedding.event_starts_at
    return if start.blank?

    lock_date = (start - Wedding::SCHEDULE_LOCK_LEAD_TIME).in_time_zone(wedding.timezone).to_date
    return unless lock_date == local_date

    AdminLifecycle::Sender.enqueue!(wedding: wedding, kind: "schedule_locking")
  end

  def enqueue_wedding_congrats(wedding, local_date)
    return if wedding.date.blank?
    return unless wedding.date + 1.day == local_date
    return unless congrats_eligible?(wedding)

    AdminLifecycle::Sender.enqueue!(wedding: wedding, kind: "wedding_congrats")
  end

  def congrats_eligible?(wedding)
    return true unless Billing.enabled?

    wedding.billing_status == "active"
  end

  def normalize_time(reference_time)
    return Time.current if reference_time.blank?

    reference_time.is_a?(Time) ? reference_time : Time.zone.parse(reference_time.to_s)
  end
end
