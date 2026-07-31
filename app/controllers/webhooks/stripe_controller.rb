module Webhooks
  class StripeController < ApplicationController
    skip_forgery_protection

    def create
      unless Billing.enabled? && Billing.webhook_secret.present?
        head :service_unavailable
        return
      end

      payload = request.body.read
      signature = request.env["HTTP_STRIPE_SIGNATURE"]

      Billing.configure_stripe!
      event = Stripe::Webhook.construct_event(payload, signature, Billing.webhook_secret)
      Billing::WebhookProcessor.call(event)
      head :ok
    rescue JSON::ParserError, Stripe::SignatureVerificationError
      head :bad_request
    end
  end
end
