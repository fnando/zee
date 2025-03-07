# frozen_string_literal: true

module Zee
  # @api private
  APPLICATION_JSON = "application/json"

  # @api private
  CHARSET = "charset"

  # @api private
  CLOSE_SQUARE_BRACKET = "]"

  # @api private
  COLON = ":"

  # @api private
  DASH = "-"

  # @api private
  DOT = "."

  # @api private
  DOUBLE_SLASH = "--"

  # @api private
  EMPTY_STRING = ""

  # @api private
  ENV_NAMES = %w[ZEE_ENV APP_ENV RACK_ENV].freeze

  # @api private
  HTML = "html"

  # @api private
  HTTP_ACCEPT = "HTTP_ACCEPT"

  # @api private
  HTTP_ACCEPT_ALL = "*/*"

  # @api private
  HTTP_ORIGIN = "HTTP_ORIGIN"

  # @api private
  HTTP_X_CSRF_TOKEN = "HTTP_X_CSRF_TOKEN"

  # @api private
  HTTP_CONTENT_TYPE = "content-type"

  # @api private
  HTTP_X_REQUESTED_WITH = "HTTP_X_REQUESTED_WITH"

  # @api private
  NOT_FOUND = "404 Not Found"

  # @api private
  NS_SEPARATOR = "::"

  # @api private
  OPEN_PAREN = "("

  # @api private
  POUND_SIGN = "#"

  # @api private
  RACK_SESSION = "rack.session"

  # @api private
  SLASH = "/"

  # @api private
  SPACE = " "

  # @api private
  SQUARE_BRACKETS = "[]"

  # @api private
  TEXT_HTML = "text/html"

  # @api private
  TEXT_PLAIN = "text/plain"

  # @api private
  UNDERSCORE = "_"

  # @api private
  ZEE_CSP_NONCE = "zee.csp_nonce"

  # @api private
  ZEE_CSRF_TOKEN = "zee.csrf_token"

  # @api private
  ZEE_KEYRING = "ZEE_KEYRING"

  # @api private
  ZEE_SESSION_KEY = "_zee_session"

  # @api private
  # The name of the output buffer variable used by erubi templates.
  BUFVAR = "@output_buffer"

  # @api private
  # The initial output buffer value used by erubi templates.
  BUFVAL = "::Zee::SafeBuffer::Erubi.new(root: true)"
end
