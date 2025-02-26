# frozen_string_literal: true

require_relative "boot"

# Build the app.
# To set up the app, use `config/config.rb`, `config/routes.rb` and initializer
# files (`config/initializers/*.rb`).
#
# Adding configuration to this file is descouraged; code reloading in
# development won't reload it.
class App < Zee::App
end

# Sets the global app instance.
# This is used by things like mailers, helpers, etc, so you don't have to pass
# the app instance around.
Zee.app = App.new
