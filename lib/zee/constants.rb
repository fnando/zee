# frozen_string_literal: true

module Zee
  HTML = "html"
  DOUBLE_SLASH = "--"
  HTTP_ACCEPT_ALL = "*/*"
  DASH = "-"
  UNDERSCORE = "_"
  EMPTY_STRING = ""
  SLASH = "/"
  OPEN_PAREN = "("
  DOT = "."
  SPACE = " "
  RACK_ZEE_APP = "zee.app"
  HTTP_ORIGIN = "HTTP_ORIGIN"
  HTTP_X_CSRF_TOKEN = "HTTP_X_CSRF_TOKEN"
  HTTP_X_REQUESTED_WITH = "HTTP_X_REQUESTED_WITH"
  HTTP_ACCEPT = "HTTP_ACCEPT"
  TEXT_HTML = "text/html"
  TEXT_PLAIN = "text/plain"
  APPLICATION_JSON = "application/json"
  RACK_SESSION = "rack.session"
  ENV_NAMES = %w[ZEE_ENV APP_ENV RACK_ENV].freeze
  ZEE_KEYRING = "ZEE_KEYRING"
  ZEE_SESSION_KEY = "_zee_session"
  ZEE_CSRF_TOKEN = "zee.csrf_token"
  ZEE_CSP_NONCE = "zee.csp_nonce"
end
