module Billing
  class WebhookProcessor
    def self.call(event)
      new(event).call
    end

    def initialize(event)
      @event = event
    end

    def call
      case @event.type
      when "checkout.session.completed"
        handle_checkout_completed(@event.data.object)
      when "customer.subscription.updated", "customer.subscription.created"
        handle_subscription(@event.data.object)
      when "customer.subscription.deleted"
        handle_subscription_deleted(@event.data.object)
      when "invoice.paid"
        handle_invoice_paid(@event.data.object)
      when "invoice.payment_failed"
        handle_invoice_payment_failed(@event.data.object)
      end
    end

    private

    def handle_checkout_completed(session)
      wedding = find_wedding_for_session(session)
      return unless wedding

      attrs = {
        stripe_customer_id: session.customer.presence || wedding.stripe_customer_id
      }

      if session.mode == "subscription" && session.subscription.present?
        attrs[:stripe_subscription_id] = session.subscription
        attrs[:billing_status] = "active"
      elsif session.mode == "payment" && session.payment_status == "paid"
        attrs[:billing_status] = "active"
        attrs[:stripe_subscription_id] = nil
      end

      wedding.update!(attrs.compact)
    end

    def handle_subscription(subscription)
      wedding = find_wedding_for_subscription(subscription)
      return unless wedding

      wedding.update!(
        stripe_customer_id: subscription.customer,
        stripe_subscription_id: subscription.id,
        billing_status: map_subscription_status(subscription.status),
        billing_period_end: period_end_at(subscription)
      )
    end

    def handle_subscription_deleted(subscription)
      wedding = find_wedding_for_subscription(subscription)
      return unless wedding

      wedding.update!(
        billing_status: "canceled",
        stripe_subscription_id: subscription.id,
        billing_period_end: period_end_at(subscription)
      )
    end

    def handle_invoice_paid(invoice)
      wedding = find_wedding_for_customer(invoice.customer)
      return unless wedding
      return if wedding.billing_status == "active"

      wedding.update!(billing_status: "active")
    end

    def handle_invoice_payment_failed(invoice)
      wedding = find_wedding_for_customer(invoice.customer)
      return unless wedding

      wedding.update!(billing_status: "past_due")
    end

    def find_wedding_for_session(session)
      wedding_id = session.client_reference_id.presence || session.metadata&.[]("wedding_id")
      wedding = Wedding.find_by(id: wedding_id) if wedding_id.present?
      wedding || find_wedding_for_customer(session.customer)
    end

    def find_wedding_for_subscription(subscription)
      wedding_id = subscription.metadata&.[]("wedding_id")
      wedding = Wedding.find_by(id: wedding_id) if wedding_id.present?
      wedding ||= Wedding.find_by(stripe_subscription_id: subscription.id)
      wedding || find_wedding_for_customer(subscription.customer)
    end

    def find_wedding_for_customer(customer_id)
      return if customer_id.blank?

      Wedding.find_by(stripe_customer_id: customer_id)
    end

    def map_subscription_status(status)
      case status.to_s
      when "active", "trialing" then "active"
      when "past_due" then "past_due"
      when "unpaid" then "unpaid"
      when "incomplete", "incomplete_expired" then "incomplete"
      when "canceled" then "canceled"
      else "incomplete"
      end
    end

    def period_end_at(subscription)
      raw = subscription.respond_to?(:current_period_end) ? subscription.current_period_end : nil
      return if raw.blank?

      Time.zone.at(raw)
    end
  end
end
