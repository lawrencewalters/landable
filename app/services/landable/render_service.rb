require_dependency 'landable/liquid'

module Landable
  class RenderService
    def self.call(page)
      new(page, page.theme).render!
    end

    def initialize(page, theme)
      @page  = page
      @theme = theme
    end

    def render!
      content = parse(page.body).render!(nil, registers: {
        page: page,
        assets: assets_for_page,
      })

      return content unless layout?

      parse(theme.body).render!({ 'body' => content }, registers: {
        page: page,
        assets: assets_for_theme,
      })
    end

    private

    attr_reader :page, :theme

    def layout?
      theme && theme.body.present?
    end

    def parse(body)
      ::Liquid::Template.parse(body)
    end

    def assets_for_page
      @assets_for_page ||=
        begin
          from_theme = theme ? theme.assets_as_hash : {}
          from_theme.merge page.assets_as_hash
        end
    end

    def assets_for_theme
      @assets_for_theme ||= theme ? theme.assets_as_hash : {}
    end
  end
end
