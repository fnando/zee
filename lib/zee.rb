# frozen_string_literal: true

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

begin
  # Phlex has a bunch of warnings. 😬
  verbose = $VERBOSE
  $VERBOSE = nil
  require "phlex"
  Phlex.eager_load
rescue LoadError
  # noop
ensure
  $VERBOSE = verbose
end

module Zee
  require_relative "zee/constants"
  require_relative "zee/version"
  require_relative "zee/app"
  require_relative "zee/enum"
  require_relative "zee/routes"
  require_relative "zee/route/parser"
  require_relative "zee/route"
  require_relative "zee/request"
  require_relative "zee/response"
  require_relative "zee/renderer"
  require_relative "zee/controller/callbacks"
  require_relative "zee/controller/authenticity_token"
  require_relative "zee/controller"
  require_relative "zee/request_handler"
  require_relative "zee/headers"
  require_relative "zee/environment"
  require_relative "zee/config"
  require_relative "zee/encrypted_file"
  require_relative "zee/main_keyring"
  require_relative "zee/secrets"
  require_relative "zee/middleware_stack"
  require_relative "zee/middleware/static"
  require_relative "zee/keyring"
  require_relative "zee/encoders/json_encoder"
  require_relative "zee/keyring/encryptor/aes"
  require_relative "zee/keyring/key"
  require_relative "zee/params"
  require_relative "zee/form_builder"
  require_relative "zee/form_builder/base"
  require_relative "zee/form_builder/layout"
  require_relative "zee/form_builder/helpers"
  require_relative "zee/form_builder/form"
  require_relative "zee/form_builder/input"
  require_relative "zee/form_builder/label"
  require_relative "zee/form_builder/hint"
  require_relative "zee/form_builder/checkbox"
end
