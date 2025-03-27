# frozen_string_literal: true

require "thor"
require "shellwords"
require "securerandom"
require "pathname"
require "logger"
require "forwardable"
require "fileutils"
require "tmpdir"
require_relative "ext/thor"
require_relative "../zee"

module Zee
  # @api private
  module CLI
    PROMPT_ALIASES = {
      development: "dev",
      production: "prod",
      test: "test"
    }.freeze

    PROMPT_COLORS = {
      development: :blue,
      production: :red,
      test: :blue
    }.freeze

    def self.start(argv = ARGV)
      Root.start(argv)
    end

    def self.before_run_hooks
      @before_run_hooks ||= Hash.new {|h, k| h[k] = [] }
    end

    def self.load_dotenv_files(*files)
      require "dotenv"
      Dotenv.load(*files)
    rescue LoadError
      # :nocov:
      if files.any? {|file| File.exist?(file) }
        raise Thor::Error,
              set_color(
                "ERROR: to use a dotenv file, add `gem \"dotenv\"` " \
                "to your Gemfile",
                :red
              )
      end

      Dotenv.load(*files) if defined?(Dotenv)
      # :nocov:
    end

    # Load plugins.
    # Plugins must be in the format of `zee/*_cli_plugin.rb`.
    # :nocov:
    Gem.find_files("zee/*_cli_plugin.rb").each do |file|
      require file
    rescue StandardError => error
      $stderr << "Error loading CLI plugin: #{file} "
      $stderr << "(#{error.class}: #{error.message})\n"
    end
    # :nocov:
  end
end
