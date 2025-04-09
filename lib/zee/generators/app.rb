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
        template ".github/workflows/ci.yml.erb", ".github/workflows/ci.yml"
        copy_file ".github/dependabot.yml"
        template ".ruby-version.erb", ".ruby-version"
        template "Gemfile.erb", "Gemfile"
      end

      def docker
        template "Dockerfile.erb", "Dockerfile"
        copy_file ".dockerignore"
        copy_file "Caddyfile"
      end

      def files
        copy_file ".gitignore"
        copy_file "app/helpers/app.rb"
        copy_file "app/assets/styles/app.css"
        copy_file "app/assets/styles/lib/reset.css"
        copy_file "app/assets/styles/lib/colors.css"
        copy_file "app/assets/styles/lib/form.css"
        copy_file "app/assets/styles/lib/theme.css"
        copy_file "app/assets/styles/lib/flash.css"
        copy_file "bin/styles"
        copy_file "bin/dev"
        copy_file "bin/zee"
        copy_file "bin/docker-entrypoint"
        copy_file "config.ru"
        copy_file "config/app.rb"
        copy_file "config/boot.rb"
        copy_file "config/config.rb"
        copy_file "config/environment.rb"
        copy_file "config/initializers/middleware.rb"
        copy_file "config/initializers/sequel.rb"
        copy_file "config/puma.rb"
        copy_file "config/locales/en/forms.yml"
        copy_file "config/locales/en/meta.yml"
        copy_file "config/routes.rb"
        template "package.json.erb", "package.json"
        copy_file "Procfile.dev"
        copy_file "public/apple-touch-icon.png"
        copy_file "public/apple-touch-icon-precomposed.png"
        copy_file "public/favicon.ico"
        copy_file "public/icon.svg"

        create_file "public/assets/.keep"
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

      def eslint
        add_npm_dependency eslint: "*", globals: "*", "@eslint/js" => "*"

        case options[:js]
        when "typescript"
          add_npm_dependency "typescript-eslint" => "*"
          copy_file "eslint.typescript.mjs", "eslint.config.mjs"
        else
          copy_file "eslint.javascript.mjs", "eslint.config.mjs"
        end
      end

      def js_bundler
        case options[:js_bundler]
        when "vite"
          add_npm_dependency "vite" => "*"
          copy_file "bin/vite", "bin/scripts"
          copy_file "vite.config.js"
        else
          add_npm_dependency "esbuild" => "*"
          copy_file "bin/esbuild", "bin/scripts"
        end
      end

      def sqlite
        return unless options[:database] == "sqlite"

        template "db/sqlite_setup.rb.erb", "db/setup.rb"
        create_file ".sqlpkg/.keep"
      end

      def test_files
        return unless options[:test] == "minitest"

        copy_file "test/test_helper.rb"
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
          copy_file "tailwind.config.js"
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
          FileUtils.chmod(0o755, "bin/docker-entrypoint")
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

      def apply_template
        return unless options[:template]

        template = options[:template]
        is_url = template.match?(/^https?:/)

        unless is_url
          template = File.expand_path(template)
          source_paths << File.dirname(template)
          template = File.basename(template)
        end

        in_root do
          apply(template, verbose: options[:verbose])
        end
      end

      def format_files
        in_root do
          run "rubocop -A", verbose: false, capture: true
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

        def node_version
          version = begin
            `node --version`.strip
          rescue Errno::ENOENT
            "22.14.0"
          end

          version.delete_prefix("v")
        end

        def app_name
          File.basename(destination_root).tr("-", "_").downcase
        end

        def database_url_for_ci
          enc = "encoding=utf8mb4"

          {
            "sqlite" => "sqlite://storage/test.db",
            "postgresql" => "postgres://postgres:postgres@localhost:5432/test",
            "mysql" => "mysql2://mysql:mysql@127.0.0.1:3306/test?#{enc}",
            "mariadb" => "mysql2://mariadb:mariadb@127.0.0.1:3306/test?#{enc}"
          }.fetch(options[:database])
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

        def deb
          base = "curl libjemalloc2"
          build = "build-essential git libyaml-dev pkg-config"

          {
            "sqlite" => {base: "#{base} sqlite3", build:},
            "postgresql" => {
              base: "#{base} postgresql-client",
              build: "#{build} libpq-dev"
            },
            "mysql" => {
              base: "#{base} default-mysql-client",
              build: "#{build} default-libmysqlclient-dev"
            },
            "mariadb" => {
              base: "#{base} default-mysql-client",
              build: "#{build} default-libmysqlclient-dev"
            }
          }.fetch(options[:database])
        end

        def js_lint_commands
          [
            ("npm run tsc -- --noEmit" if options[:js] == "typescript"),
            "npm run eslint -- --max-warnings=0"
          ].compact.join(" && ")
        end
      end
    end
  end
end
