# frozen_string_literal: true

require_relative "boot"

# Build the app.
# To set up the app, use `config/config.rb`, `config/routes.rb` and initializer
# files (`config/initializers/*.rb`).
#
# Adding configuration to this file is descouraged; code reloading in
# development won't reload it.
App = Zee::App.new
