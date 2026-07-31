namespace :admin do
  desc "Enqueue admin lifecycle emails (trial, schedule lock, day-after congrats)"
  task lifecycle_emails: :environment do
    AdminLifecyclePipelineJob.perform_now
  end
end

namespace :weddings do
  desc "Enqueue guest wedding reminder emails"
  task reminder_emails: :environment do
    WeddingReminderPipelineJob.perform_now
  end
end
