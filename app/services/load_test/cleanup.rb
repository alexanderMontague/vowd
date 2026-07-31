module LoadTest
  class Cleanup
    EMAIL_DOMAIN = "loadtest.vowd.invalid".freeze

    Result = Struct.new(
      :wedding_id,
      :run_id,
      :dry_run,
      :photos_matched,
      :photos_deleted,
      :signups_matched,
      :signups_deleted,
      :object_keys,
      keyword_init: true
    )

    def self.call(wedding_id:, run_id:, confirm: false)
      new(wedding_id:, run_id:, confirm:).call
    end

    def initialize(wedding_id:, run_id:, confirm: false)
      @wedding_id = wedding_id.to_s.strip
      @run_id = normalize_run_id(run_id)
      @confirm = ActiveModel::Type::Boolean.new.cast(confirm)
    end

    def call
      assert_wedding_allowed!
      photos = photo_scope
      signups = signup_scope
      object_keys = photos.pluck(:object_key)

      result = Result.new(
        wedding_id: @wedding_id,
        run_id: @run_id,
        dry_run: !@confirm,
        photos_matched: photos.count,
        photos_deleted: 0,
        signups_matched: signups.count,
        signups_deleted: 0,
        object_keys: object_keys
      )

      return result unless @confirm

      result.photos_deleted = photos.delete_all
      DisposableCamera::StorageClient.delete_objects!(object_keys: object_keys) if object_keys.any?
      result.signups_deleted = signups.delete_all
      result
    end

    private

    def assert_wedding_allowed!
      configured = ENV.fetch("LOADTEST_WEDDING_ID", "").to_s.strip
      raise ArgumentError, "LOADTEST_WEDDING_ID is not set" if configured.blank?
      raise ArgumentError, "wedding_id is required" if @wedding_id.blank?

      unless @wedding_id == configured
        raise ArgumentError,
              "Refusing cleanup: wedding_id=#{@wedding_id.inspect} does not match LOADTEST_WEDDING_ID=#{configured.inspect}"
      end

      return if Wedding.exists?(id: @wedding_id)

      raise ArgumentError, "Wedding #{@wedding_id.inspect} not found"
    end

    def normalize_run_id(run_id)
      value = run_id.to_s.strip
      raise ArgumentError, "RUN_ID is required (use a run id or 'all')" if value.blank?

      return "all" if value.casecmp("all").zero?

      sanitized = DisposableCamera::ObjectKeyBuilder.sanitize_load_test_run_id(value)
      raise ArgumentError, "Invalid RUN_ID: #{run_id.inspect}" if sanitized.blank?

      sanitized
    end

    def photo_scope
      fragment = DisposableCamera::ObjectKeyBuilder.load_test_object_key_fragment(
        @run_id == "all" ? nil : @run_id
      )
      DisposablePhoto.where(wedding_id: @wedding_id).where("object_key LIKE ?", "%#{fragment}%")
    end

    def signup_scope
      scope = SaveTheDateSignup.where(wedding_id: @wedding_id)
      if @run_id == "all"
        scope.where("email LIKE ?", "%@#{EMAIL_DOMAIN}")
      else
        scope.where("email LIKE ?", "lt-#{@run_id}-%@#{EMAIL_DOMAIN}")
      end
    end
  end
end
