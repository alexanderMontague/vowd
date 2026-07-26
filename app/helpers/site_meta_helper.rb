# Resolves `SiteMeta` content into the absolute URLs link previews require: scrapers
# fetch the page without a base, so a relative asset path would never load.
module SiteMetaHelper
  ABSOLUTE_URL_SCHEMES = %w[http:// https://].freeze

  def site_meta
    @site_meta ||= SiteMeta.new(current_wedding)
  end

  def site_meta_url
    absolute_site_url(request.path)
  end

  def site_meta_image
    entry = site_meta.image_candidates.find { |candidate| wedding_asset_url(candidate).present? }
    return if entry.nil?

    SiteMeta::Image.new(
      url: absolute_site_url(wedding_asset_url(entry)),
      alt: wedding_asset_alt(entry).presence || site_meta.title
    )
  end

  def absolute_site_url(path)
    return if path.blank?
    return path if path.start_with?(*ABSOLUTE_URL_SCHEMES)

    "#{request.base_url}#{path}"
  end
end
