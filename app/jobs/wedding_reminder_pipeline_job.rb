class WeddingReminderPipelineJob < ApplicationJob
  queue_as :default

  BATCH_SIZE = 500

  def perform(reference_time: nil)
    current_time = normalize_time(reference_time)

    Wedding.all.each do |wedding|
      process_wedding(wedding, current_time)
    end
  end

  private

  def process_wedding(wedding, current_time)
    config = WeddingReminders::Configuration.new(wedding:)
    return unless config.enabled?
    return unless config.send_window_open?(current_time)

    local_date = current_time.in_time_zone(config.timezone).to_date
    config.due_rules_on(local_date).each do |rule|
      enqueue_deliveries_for_rule(wedding:, config:, rule:, local_date:)
    end
  end

  def enqueue_deliveries_for_rule(wedding:, config:, rule:, local_date:)
    config.recipients_scope.find_in_batches(batch_size: BATCH_SIZE) do |guest_batch|
      guest_batch.each do |guest|
        rule.channels.each do |channel|
          next unless deliverable?(guest, channel)

          enqueue_delivery(
            guest:,
            wedding_id: wedding.id,
            reminder_key: rule.key,
            channel:,
            scheduled_for: local_date
          )
        end
      end
    end
  end

  def enqueue_delivery(guest:, wedding_id:, reminder_key:, channel:, scheduled_for:)
    delivery = NotificationDelivery.new(
      guest:,
      wedding_id:,
      reminder_key:,
      channel:,
      scheduled_for:,
      status: "queued"
    )

    if delivery.save
      WeddingReminderDeliveryJob.perform_later(delivery.id)
    end
  rescue ActiveRecord::RecordNotUnique
    nil
  end

  def deliverable?(guest, channel)
    channel == "email" && guest.email.present?
  end

  def normalize_time(reference_time)
    return Time.current if reference_time.blank?

    reference_time.is_a?(Time) ? reference_time : Time.zone.parse(reference_time.to_s)
  end
end
