module SaveTheDateModeEnforcement
  extend ActiveSupport::Concern

  included do
    before_action :redirect_to_save_the_date_unless_allowed!
  end

  private

  def redirect_to_save_the_date_unless_allowed!
    return unless save_the_date_mode_enforced?
    return if save_the_date_mode_allowed?

    redirect_to public_save_the_date_path
  end

  # Overridable so controllers that resolve a theme can exempt admin previews.
  def save_the_date_mode_enforced?
    current_wedding.save_the_date_mode?
  end

  def save_the_date_mode_allowed?
    false
  end
end
