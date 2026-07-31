# frozen_string_literal: true

# Set early from ENV; Billing.configure_stripe! refreshes the key at call sites.
Stripe.api_key = ENV["STRIPE_SECRET_KEY"].presence
