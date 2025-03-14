# frozen_string_literal: true

require_relative "lib/zee/version"

Gem::Specification.new do |spec|
  spec.name    = "zee"
  spec.version = Zee::VERSION
  spec.authors = ["Nando Vieira"]
  spec.email   = ["me@fnando.com"]
  spec.metadata = {"rubygems_mfa_required" => "true"}

  spec.summary     = "A mini web framework."
  spec.description = spec.summary
  spec.license     = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 3.3.0")

  github_url = "https://github.com/fnando/zee"
  github_tree_url = "#{github_url}/tree/v#{spec.version}"

  spec.homepage = github_url
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["bug_tracker_uri"] = "#{github_url}/issues"
  spec.metadata["source_code_uri"] = github_tree_url
  spec.metadata["changelog_uri"] = "#{github_tree_url}/CHANGELOG.md"
  spec.metadata["documentation_uri"] = "#{github_tree_url}/README.md"
  spec.metadata["license_uri"] = "#{github_tree_url}/LICENSE.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`
      .split("\x0")
      .reject {|f| f.match(%r{^(test|spec|features)/}) }
  end

  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) {|f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "base64"
  spec.add_dependency "dotenv", "~> 3.1"
  spec.add_dependency "erubi", "~> 1.13"
  spec.add_dependency "i18n", "~> 1.14"
  spec.add_dependency "json", "~> 2.10"
  spec.add_dependency "logger", "~> 1.6"
  spec.add_dependency "mini_mime", "~> 1.1"
  spec.add_dependency "public_suffix", "~> 6.0"
  spec.add_dependency "rack", "~> 3.1"
  spec.add_dependency "rake"
  spec.add_dependency "request_store", "~> 1.7"
  spec.add_dependency "securerandom", "~> 0.4"
  spec.add_dependency "superconfig", "~> 2.2"
  spec.add_dependency "terminal-table", "~> 4.0"
  spec.add_dependency "thor", "~> 1.3"
  spec.add_dependency "tilt", "~> 2.6"
  spec.add_dependency "yaml", "~> 0.4"
  spec.add_dependency "zeitwerk", "~> 2.7"
  spec.add_development_dependency "capybara"
  spec.add_development_dependency "connection_pool"
  spec.add_development_dependency "irb"
  spec.add_development_dependency "mail"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "minitest-utils"
  spec.add_development_dependency "mocha"
  spec.add_development_dependency "nokogiri"
  spec.add_development_dependency "rack-protection"
  spec.add_development_dependency "rack-session"
  spec.add_development_dependency "rack-test"
  spec.add_development_dependency "redcarpet"
  spec.add_development_dependency "redis"
  spec.add_development_dependency "rouge"
  spec.add_development_dependency "rubocop"
  spec.add_development_dependency "rubocop-fnando"
  spec.add_development_dependency "rubocop-yard"
  spec.add_development_dependency "selenium-webdriver"
  spec.add_development_dependency "sequel"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "sqlite3"
  spec.add_development_dependency "warning"
  spec.add_development_dependency "yard"
end
