# bin/rails 'email:test[me@alexmontague.ca]'

namespace :email do
  desc "Send a sample of every transactional email to a recipient. Usage: bin/rails 'email:test[you@example.com]'"
  task :test, [:recipient] => :environment do |_task, args|
    recipient = args[:recipient].presence
    abort "Usage: bin/rails 'email:test[you@example.com]'" unless recipient

    # Surface SMTP failures instead of silently swallowing them (dev sets
    # raise_delivery_errors = false), so this task is a genuine smoke test.
    ActionMailer::Base.raise_delivery_errors = true

    wedding = Wedding.find_by(id: ENV["WEDDING_ID"]) || Wedding.first
    abort "No wedding found. Create one or set WEDDING_ID." unless wedding

    accepted_guest = EmailSampleData.accepted_guest(email: recipient, wedding:)
    declined_guest = EmailSampleData.declined_guest(email: recipient, wedding:)

    deliveries = {
      "invitation" => -> { InvitationMailer.invite(accepted_guest) },
      "reminder" => lambda {
        WeddingReminderMailer.reminder(guest: accepted_guest, wedding:, subject: "Sample reminder: #{wedding.title}")
      },
      "rsvp_confirmation" => lambda {
        RSVPConfirmationMailer.confirmation(guests: [accepted_guest, declined_guest], wedding:)
      }
    }

    deliveries.each do |name, build_mail|
      print "Sending #{name} sample to #{recipient}... "
      build_mail.call.deliver_now
      puts "ok"
    rescue StandardError => e
      puts "FAILED"
      warn "  #{e.class}: #{e.message}"
    end

    puts "Done."
  end
end
