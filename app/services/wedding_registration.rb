class WeddingRegistration
  def self.call(email:, password:, password_confirmation:, slug:, title:, partner1: nil, partner2: nil)
    new(
      email: email,
      password: password,
      password_confirmation: password_confirmation,
      slug: slug,
      title: title,
      partner1: partner1,
      partner2: partner2
    ).call
  end

  def initialize(email:, password:, password_confirmation:, slug:, title:, partner1: nil, partner2: nil)
    @email = email.to_s.strip.downcase
    @password = password
    @password_confirmation = password_confirmation
    @slug = slug
    @title = title
    @partner1 = partner1.presence
    @partner2 = partner2.presence
  end

  def call
    wedding = nil
    admin_user = nil

    ActiveRecord::Base.transaction do
      wedding = Wedding.create!(
        id: @slug,
        title: @title,
        partner1: @partner1,
        partner2: @partner2,
        billing_status: "trialing",
        trial_ends_at: Billing.trial_days.days.from_now
      )

      admin_user = wedding.create_admin_user!(
        email: @email,
        password: @password,
        password_confirmation: @password_confirmation
      )
    end

    AdminLifecycle::Sender.enqueue!(wedding: wedding, kind: "welcome")

    { success: true, wedding: wedding, admin_user: admin_user, errors: [] }
  rescue ActiveRecord::RecordInvalid => e
    { success: false, wedding: nil, admin_user: nil, errors: e.record.errors.full_messages }
  end
end
