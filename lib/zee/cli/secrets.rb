module Zee
  class CLI < Thor
    class Secrets < Thor
      desc "edit", "Edit secrets"
      option :environment,
             desc: "Environment to edit",
             type: :string,
             aliases: "-e",
             required: true
      # :nocov:
      def edit
        env = options["environment"]

        key = begin
          MasterKey.read(env)
        rescue MasterKey::MissingKeyError
          say_error "ERROR: Set ZEE_MASTER_KEY or create #{key_file}", :red
          say "\nTo create a new key, run the following command:\n" \
              "zee secrets create -e #{env}"
          exit 1
        end

        tmp_file = File.join(Dir.tmpdir, "#{env}-#{SecureRandom.hex(8)}.yml")
        secrets_file = Pathname(
          File.join(Dir.pwd, "config/secrets", "#{env}.yml.enc")
        )

        encrypted_file = EncryptedFile.new(path: secrets_file, key:)

        if secrets_file.file?
          content = encrypted_file.read
          File.write(tmp_file, content)
        end

        say "Editing #{secrets_file.relative_path_from(Dir.pwd)}…"
        system(*Shellwords.split(editor), tmp_file)
        updated_content = File.binread(tmp_file)
        encrypted_file.write(updated_content) if content != updated_content
        say "File encrypted and saved."
      ensure
        FileUtils.rm_rf(tmp_file)
      end
      # :nocov:

      desc "create", "Create secrets"
      option :environment,
             desc: "Environment to create",
             type: :string,
             aliases: "-e",
             required: true
      def create
        env = options["environment"]
        key_file = "config/secrets/#{env}.key"
        secrets_file = "config/secrets/#{env}.yml.enc"

        FileUtils.mkdir_p("config/secrets")

        if File.file?(key_file)
          say_error "ERROR: #{key_file} already exists", :red
          exit 1
        end

        if File.file?(secrets_file)
          say_error "ERROR: #{secrets_file} already exists", :red
          exit 1
        end

        key = SecureRandom.hex(16)
        File.write(key_file, key)
        content = <<~YAML
          ---
          # Add your secrets here
        YAML

        EncryptedFile.new(path: secrets_file, key:).write(content)
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
