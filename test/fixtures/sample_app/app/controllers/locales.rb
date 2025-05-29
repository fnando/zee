# frozen_string_literal: true

module Controllers
  class Locales < Base
    def show
      I18n.available_locales = %w[en pt-BR]
      I18n.locale = params[:locale]
    end
  end
end
