module Public
  class BaseController < ApplicationController
    include WeddingConcern
    include SaveTheDateModeEnforcement

    layout "public"

    before_action :require_wedding!
  end
end
