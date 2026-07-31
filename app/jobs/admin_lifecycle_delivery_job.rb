class AdminLifecycleDeliveryJob < ApplicationJob
  queue_as :default

  def perform(delivery_id)
    delivery = AdminNotificationDelivery.find_by(id: delivery_id)
    return if delivery.blank? || delivery.status == "sent"

    wedding = Wedding.find(delivery.wedding_id)
    admin = wedding.admin_user
    raise "Admin user missing for wedding=#{wedding.id}" if admin.blank?

    mailer = AdminLifecycle::Sender::MAILERS.fetch(delivery.kind)
    mailer.call(admin, delivery).deliver_now
    delivery.mark_sent!
  rescue StandardError => e
    delivery&.mark_failed!(e.message)
    raise
  end
end
