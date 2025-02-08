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

  spec.add_dependency "mini_mime", "~> 1.1"
  spec.add_dependency "public_suffix", "~> 6.0"
  spec.add_dependency "rack", "~> 3.1"
  spec.add_dependency "superconfig", "~> 2.1"
  spec.add_dependency "thor", "~> 1.3"
  spec.add_dependency "tilt", "~> 2.6"
  spec.add_dependency "zeitwerk", "~> 2.7"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "minitest-utils"
  spec.add_development_dependency "rack-test"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rubocop"
  spec.add_development_dependency "rubocop-fnando"
  spec.add_development_dependency "simplecov"
end
