module AdminLifecycle
  class Sender
    MAILERS = {
      "welcome" => ->(admin, _delivery) { AdminLifecycleMailer.welcome(admin) },
      "trial_expiring_3d" => ->(admin, _delivery) { AdminLifecycleMailer.trial_expiring(admin, days_left: 3) },
      "trial_expiring_1d" => ->(admin, _delivery) { AdminLifecycleMailer.trial_expiring(admin, days_left: 1) },
      "schedule_locking" => ->(admin, _delivery) { AdminLifecycleMailer.schedule_locking(admin) },
      "wedding_congrats" => ->(admin, _delivery) { AdminLifecycleMailer.wedding_congrats(admin) }
    }.freeze

    def self.enqueue!(wedding:, kind:)
      new(wedding: wedding, kind: kind).enqueue!
    end

    def initialize(wedding:, kind:)
      @wedding = wedding
      @kind = kind.to_s
    end

    def enqueue!
      raise ArgumentError, "Unknown kind=#{@kind}" unless MAILERS.key?(@kind)
      return if @wedding.admin_user&.email.blank?

      delivery = AdminNotificationDelivery.create!(
        wedding_id: @wedding.id,
        kind: @kind,
        status: "queued"
      )
      AdminLifecycleDeliveryJob.perform_later(delivery.id)
      delivery
    rescue ActiveRecord::RecordNotUnique
      nil
    end
  end
end
