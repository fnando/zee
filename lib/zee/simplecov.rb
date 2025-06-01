# frozen_string_literal: true

module Zee
  # @api private
  class Simplecov
  end
end

require "simplecov"

SimpleCov.profiles.define :zee do
  load_profile "bundler_filter"
  load_profile "test_frameworks"
  add_filter %r{^/config/}
  add_filter %r{^/db/}

  Dir["app/*"].each do |dir|
    next unless File.directory?(dir)

    title = File.basename(dir).tr("_", " ").capitalize

    add_group(title, dir) if Dir["#{dir}/**/*.rb"].any?
  end

  track_files "app/**/*.rb"
end

at_exit { SimpleCov.at_exit_behavior }
