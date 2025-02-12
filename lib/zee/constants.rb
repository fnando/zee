# frozen_string_literal: true

module Zee
  RACK_ZEE_APP = "zee.app"
  HTTP_ACCEPT = "HTTP_ACCEPT"
  TEXT_HTML = "text/html"
  TEXT_PLAIN = "text/plain"
  APPLICATION_JSON = "application/json"
  RACK_SESSION = "rack.session"
  ENV_NAMES = %w[ZEE_ENV APP_ENV RACK_ENV].freeze
  ZEE_MASTER_KEY = "ZEE_MASTER_KEY"
  ZEE_SESSION_KEY = "_zee_session"
end
