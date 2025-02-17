# frozen_string_literal: true

module Zee
  class CLI < Command
    module Secrets
      class Helpers < CLI::Helpers
        # :nocov:
        def editor
          ENV["EDITOR"] || ENV["VISUAL"] || "vi"
        end
        # :nocov:
      end

      def self.included(base)
        base.class_eval do
          desc "secrets:edit", "Edit secrets"
          option :environment,
                 desc: "Environment to edit",
                 type: :string,
                 aliases: "-e",
                 required: true
          # :nocov:
          define_method :"secrets:edit" do
            env = options["environment"]

            keyring = begin
              MainKeyring.read(env)
            rescue MainKeyring::MissingKeyError
              say_error "ERROR: Set ZEE_KEYRING or create #{key_file}", :red
              say "\nTo create a new key, run the following command:\n" \
                  "zee secrets create -e #{env}"
              exit 1
            end

            tmp_file = File.join(Dir.tmpdir,
                                 "#{env}-#{SecureRandom.hex(8)}.yml")
            secrets_file = Pathname(
              File.join(Dir.pwd, "config/secrets", "#{env}.yml.enc")
            )

            encrypted_file = EncryptedFile.new(path: secrets_file, keyring:)

            if secrets_file.file?
              content = encrypted_file.read
              File.write(tmp_file, content)
            end

            say "Editing #{secrets_file.relative_path_from(Dir.pwd)}…"
            system(*Shellwords.split(secrets_helpers.editor), tmp_file)
            updated_content = File.binread(tmp_file)
            encrypted_file.write(updated_content) if content != updated_content
            say "File encrypted and saved."
          ensure
            FileUtils.rm_rf(tmp_file)
          end
          # :nocov:

          desc "secrets:create", "Create secrets"
          option :environment,
                 desc: "Environment to create",
                 type: :string,
                 aliases: "-e",
                 required: true
          define_method :"secrets:create" do
            env = options["environment"]
            key_file = "config/secrets/#{env}.key"
            secrets_file = "config/secrets/#{env}.yml.enc"

            FileUtils.mkdir_p("config/secrets")

            if File.file?(key_file)
              raise Thor::Error,
                    set_color("ERROR: #{key_file} already exists", :red)
            end

            if File.file?(secrets_file)
              raise Thor::Error,
                    set_color("ERROR: #{secrets_file} already exists", :red)
            end

            key = SecureRandom.hex(32)
            digest_salt = SecureRandom.hex(32)

            File.write(key_file, JSON.dump("0" => key, digest_salt:))
            content = <<~YAML
              ---
              # The session secret is used to sign the session cookie.
              # It will also be used to sign the CSRF token.
              session_secret: #{SecureRandom.hex(64)}
            YAML

            keyring = Zee::Keyring.new({"0" => key}, digest_salt:)

            EncryptedFile.new(path: secrets_file, keyring:).write(content)
            File.chmod(0o600, key_file)
          end
        end
      end
    end
  end
end
