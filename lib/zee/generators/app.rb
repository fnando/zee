# frozen_string_literal: true

module Zee
  module Generators
    class App < Thor::Group
      include Thor::Actions

      attr_accessor :options

      def self.source_root
        File.join(__dir__, "app")
      end

      def templates
        template "Gemfile.erb", "Gemfile"
        template ".ruby-version.erb", ".ruby-version"
        template ".rubocop.yml.erb", ".rubocop.yml"
        template ".env.development.erb", ".env.development"
        template ".env.test.erb", ".env.test"
      end

      def files
        copy_file ".gitignore"
        copy_file "bin/dev"
        copy_file "bin/zee"
        copy_file "tmp/.keep"
        copy_file "config/app.rb"
        copy_file "config/boot.rb"
        copy_file "config/puma.rb"
        copy_file "app/helpers/app.rb"
        copy_file "config/routes.rb"
        copy_file "Procfile.dev"
        copy_file "test/test_helper.rb"
        copy_file "config.ru"
        copy_file "public/favicon.ico"
        copy_file "public/icon.svg"
        copy_file "public/apple-touch-icon.png"
        copy_file "config/environment.rb"
        create_file "storage/.keep"
        create_file "db/migrations/.keep"
      end

      def models
        create_file "app/models/.keep"
      end

      def controllers
        copy_file "app/controllers/base.rb"
        copy_file "app/controllers/pages.rb"
      end

      def views
        copy_file "app/views/pages/home.html.erb"
        copy_file "app/views/layouts/application.html.erb"
      end

      def keys
        create_key :development
        create_key :test
      end

      def permissions
        in_root do
          FileUtils.chmod(0o755, "bin/dev")
          FileUtils.chmod(0o755, "bin/zee")
        end
      end

      def install
        return if options[:skip_bundle]

        in_root do
          run "bundle install"
          run "bundle lock --add-platform=x86_64-linux"

          if RUBY_PLATFORM.start_with?("arm64")
            run "bundle lock --add-platform=aarch64-linux"
          end
        end
      end

      no_commands do
        def create_key(env)
          digest_salt = SecureRandom.hex(32)
          key = SecureRandom.hex(32)
          key_file = "config/secrets/#{env}.key"
          raw = JSON.dump("0" => key, digest_salt:)
          create_file key_file, raw
          saved_key = File.read(File.join(destination_root, key_file))
          secrets_file =
            "#{destination_root}/config/secrets/#{env}.yml.enc"
          relative_secrets_file = Pathname
                                  .new(secrets_file)
                                  .relative_path_from(destination_root)
          FileUtils.chmod(0o600, File.join(destination_root, key_file))

          # :nocov:
          if raw != saved_key
            say_status :skip, relative_secrets_file, :yellow
            return
          end
          # :nocov:

          keyring = Keyring.new({"0" => key}, digest_salt:)

          encrypted_file = EncryptedFile.new(
            path: secrets_file,
            keyring:
          )

          encrypted_file.write <<~YAML
            ---
            # The session secret is used to sign the session cookie.
            # It will also be used to sign the CSRF token.
            session_secret: #{SecureRandom.hex(64)}
          YAML

          say_status :create, relative_secrets_file, :green
        end

        def version(version, size = 3)
          version.split(".").take(size).join(".")
        end

        def app_name
          File.basename(destination_root).tr("-", "_").downcase
        end

        def database_url(env)
          case options[:database]
          when "sqlite"
            "sqlite://storage/#{env}.db"
          when "postgresql"
            "postgres:///#{app_name}_#{env}"
          when "mysql", "mariadb"
            "mysql2:///#{app_name}_#{env}?encoding=utf8mb4"
          else
            raise "Unsupported database: #{options[:database]}"
          end
        end
      end
    end
  end
end
