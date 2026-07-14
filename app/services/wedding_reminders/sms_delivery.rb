require "net/http"
require "uri"
require "json"

module WeddingReminders
  class SmsDelivery
    LOG_MODE = "log"
    WEBHOOK_MODE = "webhook"

    class << self
      def deliver!(guest:, message:, reminder_key:)
        mode = ENV.fetch("VOWD_SMS_MODE", LOG_MODE)

        case mode
        when LOG_MODE
          Rails.logger.info("SMS delivery log mode: guest_id=#{guest.id} reminder_key=#{reminder_key} message=#{message.inspect}")
        when WEBHOOK_MODE
          deliver_via_webhook!(guest:, message:, reminder_key:)
        else
          raise ArgumentError, "Unsupported VOWD_SMS_MODE=#{mode.inspect}"
        end
      end

      private

      def deliver_via_webhook!(guest:, message:, reminder_key:)
        webhook_url = ENV["VOWD_SMS_WEBHOOK_URL"].to_s
        raise "VOWD_SMS_WEBHOOK_URL is required for webhook SMS mode" if webhook_url.blank?

        uri = URI.parse(webhook_url)
        request = Net::HTTP::Post.new(uri)
        request["Content-Type"] = "application/json"
        request.body = {
          to: guest.phone_number,
          message: message,
          guest_id: guest.id,
          wedding_id: guest.wedding_id,
          reminder_key: reminder_key
        }.to_json

        response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
          http.request(request)
        end

        return if response.is_a?(Net::HTTPSuccess)

        raise "SMS webhook delivery failed with status=#{response.code} body=#{response.body}"
      end
    end
  end
end
