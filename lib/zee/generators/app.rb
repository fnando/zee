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
        template ".env.development.erb", ".env.development"
        template ".env.test.erb", ".env.test"
        template ".rubocop.yml.erb", ".rubocop.yml"
        template ".ruby-version.erb", ".ruby-version"
        template "Gemfile.erb", "Gemfile"
      end

      def files
        copy_file ".gitignore"
        copy_file "app/helpers/app.rb"
        copy_file "app/assets/styles/app.css"
        copy_file "app/assets/styles/lib/reset.css"
        copy_file "app/assets/styles/lib/colors.css"
        copy_file "bin/styles"
        copy_file "bin/scripts"
        copy_file "bin/dev"
        copy_file "bin/zee"
        copy_file "config.ru"
        copy_file "config/app.rb"
        copy_file "config/boot.rb"
        copy_file "config/config.rb"
        copy_file "config/environment.rb"
        copy_file "config/initializers/middleware.rb"
        copy_file "config/initializers/sequel.rb"
        copy_file "config/puma.rb"
        copy_file "config/routes.rb"
        copy_file "package.json"
        copy_file "Procfile.dev"
        copy_file "public/apple-touch-icon.png"
        copy_file "public/favicon.ico"
        copy_file "public/icon.svg"

        create_file "storage/.keep"
        create_file "db/migrations/.keep"
        create_file "app/assets/styles/app/.keep"
        create_file "app/assets/scripts/app/.keep"
        create_file "app/assets/images/.keep"
        create_file "app/assets/fonts/.keep"
        create_file "tmp/.keep"
        create_file "log/.keep"
        create_file "app/models/.keep"
      end

      def sqlite
        return unless options[:database] == "sqlite"

        template "db/sqlite_setup.rb.erb", "db/setup.rb"
        create_file ".sqlpkg/.keep"
      end

      def test_files
        return unless options[:test] == "minitest"

        copy_file "test/test_helper.rb"
        copy_file "test/requests/pages_test.rb"
        copy_file "test/integration/pages_test.rb"
      end

      def spec_files
        return unless options[:test] == "rspec"

        copy_file "spec/spec_helper.rb"
        copy_file "spec/features/pages_spec.rb"
        copy_file "spec/requests/pages_spec.rb"
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

      def js
        case options[:js]
        when "typescript"
          copy_file "app/assets/scripts/app.ts"
          copy_file "tsconfig.json"
          add_npm_dependency "typescript" => "*"
        when "js"
          copy_file "app/assets/scripts/app.js"
        else
          raise Thor::Error, "Unsupported JS option: #{options[:js].inspect}"
        end
      end

      def css
        case options[:css]
        when "tailwind"
          add_npm_dependency "tailwindcss" => "*", "@tailwindcss/cli" => "*"
        when "css"
          # noop
        else
          raise Thor::Error, "Unsupported CSS option: #{options[:css].inspect}"
        end
      end

      def permissions
        in_root do
          FileUtils.chmod(0o755, "bin/styles")
          FileUtils.chmod(0o755, "bin/scripts")
          FileUtils.chmod(0o755, "bin/dev")
          FileUtils.chmod(0o755, "bin/zee")
        end
      end

      def bundle_install
        return if options[:skip_bundle]

        in_root do
          run "bundle install"
          run "bundle lock --add-platform=x86_64-linux"

          if RUBY_PLATFORM.start_with?("arm64")
            run "bundle lock --add-platform=aarch64-linux"
          end
        end
      end

      def npm_install
        return if options[:skip_npm]

        in_root do
          run "npm install"
        end
      end

      no_commands do
        def add_npm_dependency(**deps)
          path = File.join(destination_root, "package.json")
          json = JSON.parse(File.read(path))

          json["dependencies"] ||= {}

          deps.each do |name, version|
            if json["dependencies"].key?(name)
              # :nocov:
              say_status :skip, %[npm package "#{name}" already added], :blue
              # :nocov:
            else
              json["dependencies"][name] = version
              say_status :add, %[npm package "#{name}"], :green
            end
          end

          File.write(path, JSON.pretty_generate(json))
        end

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

            # Set a digest salt for keyring.
            digest_salt: #{SecureRandom.hex(64)}
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
