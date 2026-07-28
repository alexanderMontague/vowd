ENV["RAILS_ENV"] ||= "test"
ENV["APP_BASE_DOMAIN"] ||= "example.test"
ENV["APP_PORT"] ||= "3003"

require_relative "../config/environment"
require "rails/test_help"
require "minitest/mock"

module ActiveSupport
  class TestCase
    fixtures :all

    def create_wedding(attrs = {})
      defaults = {
        id: "wedding-#{SecureRandom.hex(4)}",
        title: "Test Wedding",
        partner1: "Britt",
        partner2: "Alex",
        date: Date.new(2027, 7, 10),
        ceremony_time: "4:00 PM",
        timezone: "America/Toronto",
        meal_options: %w[Chicken Vegetarian]
      }
      Wedding.create!(defaults.merge(attrs))
    end

    def create_admin_for(wedding, attrs = {})
      defaults = {
        email: "admin-#{SecureRandom.hex(4)}@example.com",
        password: "password",
        password_confirmation: "password",
        wedding: wedding
      }
      AdminUser.create!(defaults.merge(attrs))
    end

    def sign_in_admin(admin)
      host_wedding!(admin.wedding)
      post admin_login_path, params: { email: admin.email, password: "password" }
    end

    def host_wedding!(wedding)
      host! AppHost.subdomain_host(wedding.id)
    end

    def host_platform!
      host! AppHost.base_domain
    end

    def get_iframe(path, **kwargs)
      get path, **kwargs, headers: (kwargs[:headers] || {}).merge("Sec-Fetch-Dest" => "iframe")
    end

    def with_env(overrides)
      original = overrides.keys.index_with { |key| ENV.fetch(key, nil) }
      overrides.each { |key, value| value.nil? ? ENV.delete(key) : ENV[key] = value }
      yield
    ensure
      original.each { |key, value| value.nil? ? ENV.delete(key) : ENV[key] = value }
    end
  end
end
