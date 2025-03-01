# frozen_string_literal: true

require "openssl"
require "base64"
require "rack"
require "mini_mime"
require "tilt"
require "erubi"
require "erubi/capture_block"
require "superconfig"
require "forwardable"
require "yaml"
require "json"
require "securerandom"
require "i18n"

require_relative "zee/constants"
require_relative "zee/enum"

require "zeitwerk"
loader = Zeitwerk::Loader.for_gem
loader.inflector.inflect(
  "aes" => "AES",
  "cli" => "CLI",
  "html" => "HTML",
  "json_encoder" => "JSONEncoder"
)
loader.ignore("#{__dir__}/sequel")
loader.setup
