# frozen_string_literal: true

# Single-plan billing config. Create the Product/Price in Stripe Dashboard, then
# point STRIPE_PRICE_ID at it. Use STRIPE_CHECKOUT_MODE=payment for a one-time
# Wedding Pass, or subscription for recurring hosting.
module Billing
  module_function

  STATUSES = %w[trialing active past_due canceled unpaid incomplete].freeze
  ACCESS_STATUSES = %w[trialing active past_due].freeze
  CHECKOUT_MODES = %w[payment subscription].freeze
  DEFAULT_TRIAL_DAYS = 14

  def enabled?
    secret_key.present? && price_id.present?
  end

  def secret_key
    ENV["STRIPE_SECRET_KEY"].presence
  end

  def publishable_key
    ENV["STRIPE_PUBLISHABLE_KEY"].presence
  end

  def webhook_secret
    ENV["STRIPE_WEBHOOK_SECRET"].presence
  end

  def price_id
    ENV["STRIPE_PRICE_ID"].presence
  end

  def checkout_mode
    mode = ENV.fetch("STRIPE_CHECKOUT_MODE", "payment").to_s.strip.downcase
    CHECKOUT_MODES.include?(mode) ? mode : "payment"
  end

  def subscription_mode?
    checkout_mode == "subscription"
  end

  def trial_days
    days = ENV.fetch("BILLING_TRIAL_DAYS", DEFAULT_TRIAL_DAYS.to_s).to_i
    days.positive? ? days : DEFAULT_TRIAL_DAYS
  end

  def configure_stripe!
    return unless secret_key

    Stripe.api_key = secret_key
  end
end
