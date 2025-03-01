# frozen_string_literal: true

module Zee
  APPLICATION_JSON = "application/json"
  CLOSE_SQUARE_BRACKET = "]"
  COLON = ":"
  DASH = "-"
  DOT = "."
  DOUBLE_SLASH = "--"
  EMPTY_STRING = ""
  ENV_NAMES = %w[ZEE_ENV APP_ENV RACK_ENV].freeze
  HTML = "html"
  HTTP_ACCEPT = "HTTP_ACCEPT"
  HTTP_ACCEPT_ALL = "*/*"
  HTTP_ORIGIN = "HTTP_ORIGIN"
  HTTP_X_CSRF_TOKEN = "HTTP_X_CSRF_TOKEN"
  HTTP_X_REQUESTED_WITH = "HTTP_X_REQUESTED_WITH"
  NS_SEPARATOR = "::"
  OPEN_PAREN = "("
  RACK_SESSION = "rack.session"
  SLASH = "/"
  SPACE = " "
  SQUARE_BRACKETS = "[]"
  TEXT_HTML = "text/html"
  TEXT_PLAIN = "text/plain"
  UNDERSCORE = "_"
  ZEE_CSP_NONCE = "zee.csp_nonce"
  ZEE_CSRF_TOKEN = "zee.csrf_token"
  ZEE_KEYRING = "ZEE_KEYRING"
  ZEE_SESSION_KEY = "_zee_session"

  # @private
  # The name of the output buffer variable used by erubi templates.
  BUFVAR = "@output_buffer"

  # @private
  # The initial output buffer value used by erubi templates.
  BUFVAL = "::Zee::SafeBuffer::Erubi.new(root: true)"
end
