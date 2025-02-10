module Zee
  class MasterKey
    MissingKeyError = Class.new(StandardError)

    def self.read(env)
      key = ENV[ZEE_MASTER_KEY]
      key_file = "config/secrets/#{env}.key"

      return key if key
      return File.read(key_file).chomp if File.file?(key_file)

      raise MissingKeyError, "Set ZEE_MASTER_KEY or create #{key_file}"
    end
  end
end
