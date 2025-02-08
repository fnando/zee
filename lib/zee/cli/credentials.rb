# frozen_string_literal: true

module Zee
  class CLI < Thor
    class Credentials < Thor
      desc "edit", "Edit credentials"
      option :environment,
             desc: "Environment to edit",
             type: :string,
             aliases: "-e",
             required: true
      # :nocov:
      def edit
        env = options["environment"]
        key = ENV["ZEE_MASTER_KEY"] || read_key(env)
        tmp_file = File.join(Dir.tmpdir, "#{env}-#{SecureRandom.hex(8)}.yml")
        credentials_file = Pathname(
          File.join(Dir.pwd, "config/credentials", "#{env}.yml.enc")
        )

        encrypted_file = EncryptedFile.new(path: credentials_file, key:)

        if credentials_file.file?
          content = encrypted_file.read
          File.write(tmp_file, content)
        end

        say "Editing #{credentials_file.relative_path_from(Dir.pwd)}…"
        system(*Shellwords.split(editor), tmp_file)
        updated_content = File.binread(tmp_file)
        encrypted_file.write(updated_content) if content != updated_content
        say "File encrypted and saved."
      ensure
        FileUtils.rm_rf(tmp_file)
      end
      # :nocov:

      desc "create", "Create credentials"
      option :environment,
             desc: "Environment to create",
             type: :string,
             aliases: "-e",
             required: true
      def create
        env = options["environment"]
        key_file = "config/credentials/#{env}.key"
        credentials_file = "config/credentials/#{env}.yml.enc"

        FileUtils.mkdir_p("config/credentials")

        if File.file?(key_file)
          say_error "ERROR: #{key_file} already exists", :red
          exit 1
        end

        if File.file?(credentials_file)
          say_error "ERROR: #{credentials_file} already exists", :red
          exit 1
        end

        key = SecureRandom.hex(16)
        File.write(key_file, key)
        content = <<~YAML
          ---
          # Add your secrets here
        YAML

        EncryptedFile.new(path: credentials_file, key:).write(content)
        File.chmod(0o600, key_file)
      end

      no_commands do
        # :nocov:
        def read_key(env)
          key_file = "config/credentials/#{env}.key"

          unless File.file?(key_file)
            say_error "ERROR: Set ZEE_MASTER_KEY or create #{key_file}", :red
            say "\nTo create a new key, run the following command:\n" \
                "zee credentials create -e #{env}"
            exit 1
          end

          File.read("config/credentials/#{env}.key").chomp
        end

        def editor
          ENV["EDITOR"] || ENV["VISUAL"] || "vi"
        end
        # :nocov:
      end
    end
  end
end
