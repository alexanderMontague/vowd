# frozen_string_literal: true

namespace :loadtest do
  desc "Run a k6 load test scenario (SCENARIO=mixed|browse|dispo_upload BASE_URL=... VUS=10 DURATION=30s)"
  task run: :environment do
    scenario = ENV.fetch("SCENARIO", "mixed")
    script = Rails.root.join("loadtest/k6/scenarios/#{scenario}.js")
    abort "Unknown scenario: #{scenario} (expected browse, dispo_upload, or mixed)" unless script.exist?

    unless system("command -v k6 >/dev/null 2>&1")
      abort "k6 is not installed. Install with: brew install k6"
    end

    run_id = ENV["RUN_ID"].presence || Time.now.utc.strftime("%Y%m%dT%H%M%SZ-#{SecureRandom.hex(3)}")
    base_url = ENV.fetch("BASE_URL") do
      abort "BASE_URL is required (e.g. https://loadtest.vowd.site)"
    end

    results_dir = Rails.root.join("loadtest/results/#{run_id}")
    FileUtils.mkdir_p(results_dir)

    env = {
      "BASE_URL" => base_url,
      "RUN_ID" => run_id,
      "VUS" => ENV.fetch("VUS", "10"),
      "DURATION" => ENV.fetch("DURATION", "30s"),
      "RESULTS_DIR" => results_dir.to_s
    }

    puts "Starting load test run_id=#{run_id} scenario=#{scenario} base_url=#{base_url}"
    puts "Results -> #{results_dir}"

    cmd = [
      "k6", "run",
      "--out", "json=#{results_dir}/raw.json",
      "-e", "BASE_URL=#{base_url}",
      "-e", "RUN_ID=#{run_id}",
      "-e", "VUS=#{env['VUS']}",
      "-e", "DURATION=#{env['DURATION']}",
      "-e", "RESULTS_DIR=#{results_dir}",
      script.to_s
    ]

    success = system(env, *cmd)
    puts "Finished run_id=#{run_id} (cleanup with: bin/rails loadtest:cleanup RUN_ID=#{run_id} CONFIRM=yes)"
    abort "k6 exited with an error" unless success
  end

  desc "Dry-run or delete load-test photos/signups for RUN_ID (or RUN_ID=all). Requires LOADTEST_WEDDING_ID and CONFIRM=yes to delete."
  task cleanup: :environment do
    wedding_id = ENV["WEDDING"].presence || ENV.fetch("LOADTEST_WEDDING_ID", "")
    run_id = ENV.fetch("RUN_ID") { abort "RUN_ID is required (specific id or 'all')" }
    confirm = ENV["CONFIRM"]

    begin
      result = LoadTest::Cleanup.call(wedding_id:, run_id:, confirm:)
    rescue ArgumentError => e
      abort e.message
    end

    mode = result.dry_run ? "DRY RUN (set CONFIRM=yes to delete)" : "DELETED"
    puts "#{mode} wedding=#{result.wedding_id} run_id=#{result.run_id}"
    puts "  photos matched=#{result.photos_matched} deleted=#{result.photos_deleted}"
    puts "  signups matched=#{result.signups_matched} deleted=#{result.signups_deleted}"
    puts "  object keys: #{result.object_keys.size}"
    result.object_keys.first(20).each { |key| puts "    - #{key}" }
    puts "    … (#{result.object_keys.size - 20} more)" if result.object_keys.size > 20
  end
end
