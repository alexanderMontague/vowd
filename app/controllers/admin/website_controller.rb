module Admin
  class WebsiteController < Admin::BaseController
    include WeddingContentParams

    before_action :set_wedding
    before_action :ensure_section, only: %i[show update], if: -> { @wedding.configured? }

    def show
      return if setup_mode? || performed?
    end

    def update
      if setup_mode?
        update_setup
        return
      end
      return if performed?

      attrs = build_wedding_attributes

      if @wedding.errors.any?
        @wedding.assign_attributes(attrs)
        flash.now[:alert] = @wedding.errors.full_messages.to_sentence
        render :show, status: :unprocessable_entity
        return
      end

      if @wedding.update(attrs)
        respond_to do |format|
          format.json { render json: { ok: true } }
          format.html do
            redirect_to admin_website_section_path(section: @section.key),
                        notice: "Wedding details saved."
          end
        end
      else
        respond_to do |format|
          format.json do
            render json: { ok: false, error: @wedding.errors.full_messages.to_sentence },
                   status: :unprocessable_entity
          end
          format.html do
            flash.now[:alert] = @wedding.errors.full_messages.to_sentence
            render :show, status: :unprocessable_entity
          end
        end
      end
    end

    private

    def set_wedding
      @wedding = current_wedding
    end

    def setup_mode?
      !@wedding.configured?
    end

    def ensure_section
      if params[:section].blank?
        redirect_to admin_website_section_path(section: WebsiteSections::DEFAULT_KEY)
        return
      end

      @section = WebsiteSections.find(params[:section])
      return if @section

      redirect_to admin_website_section_path(section: WebsiteSections::DEFAULT_KEY)
    end

    def update_setup
      attrs = build_wedding_attributes

      if @wedding.errors.any?
        @wedding.assign_attributes(attrs)
        flash.now[:alert] = @wedding.errors.full_messages.to_sentence
        render :show, status: :unprocessable_entity
        return
      end

      if @wedding.update(attrs)
        notice = if @wedding.configured?
                   "Wedding details saved. Your admin dashboard is ready."
                 else
                   "Saved. Add both partners and a wedding date to unlock the rest of admin."
                 end
        redirect_to(@wedding.configured? ? admin_website_section_path(section: WebsiteSections::DEFAULT_KEY) : admin_website_path,
                    notice: notice)
      else
        flash.now[:alert] = @wedding.errors.full_messages.to_sentence
        render :show, status: :unprocessable_entity
      end
    end
  end
end
