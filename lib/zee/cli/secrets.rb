# frozen_string_literal: true

module Zee
  module CLI
    class Secrets < Command
      class_option :environment,
                   desc: "Environment to edit",
                   type: :string,
                   aliases: "-e",
                   required: true

      desc "edit", "Edit secrets"
      # :nocov:
      def edit
        env = options["environment"]
        key_file = "config/secrets/#{env}.key"

        keyring = begin
          Keyring.load(key_file)
        rescue Keyring::MissingKeyError
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
        system(*Shellwords.split(editor), tmp_file)
        updated_content = File.binread(tmp_file)
        encrypted_file.write(updated_content) if content != updated_content
        File.chmod(0o600, key_file)
        say "File encrypted and saved."
      ensure
        FileUtils.rm_rf(tmp_file)
      end
      # :nocov:

      desc "create", "Create secrets"
      def create
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

          # Set a digest salt for keyring.
          digest_salt: #{SecureRandom.hex(64)}
        YAML

        keyring = Zee::Keyring.new({"0" => key}, digest_salt:)

        EncryptedFile.new(path: secrets_file, keyring:).write(content)
        File.chmod(0o600, key_file)
      end

      no_commands do
        # :nocov:
        def editor
          ENV["EDITOR"] || ENV["VISUAL"] || "vi"
        end
        # :nocov:
      end
    end
  end
end
