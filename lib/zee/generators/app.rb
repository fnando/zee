# frozen_string_literal: true

module Zee
  class Generator < Thor::Group
    include Thor::Actions

    attr_accessor :options

    def self.source_root
      File.join(__dir__, "app")
    end

    def templates
      template "Gemfile.erb", "Gemfile"
      template ".ruby-version.erb", ".ruby-version"
      template ".rubocop.yml.erb", ".rubocop.yml"
      template "config/app.rb.erb", "config/app.rb"
    end

    def files
      copy_file ".gitignore"
      copy_file "tmp/.keep"
      copy_file "config/boot.rb"
      copy_file "config/puma.rb"
      copy_file "config/routes.rb"
      copy_file "Procfile.dev"
      copy_file "config.ru"
      copy_file "config/environment.rb"
    end

    def controllers
      copy_file "app/controllers/base.rb"
      copy_file "app/controllers/pages.rb"
    end

    def views
      copy_file "app/views/pages/home.html.erb"
      copy_file "app/views/layouts/application.html.erb"
    end

    def install
      return if options[:skip_bundle]

      in_root do
        run "bundle install"
      end
    end

    no_commands do
      def version(version, size = 3)
        version.split(".").take(size).join(".")
      end
    end
  end
end
