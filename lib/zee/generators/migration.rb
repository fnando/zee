# frozen_string_literal: true

module Zee
  module Generators
    class Migration < Thor::Group
      include Thor::Actions

      attr_accessor :options

      def self.source_root
        File.join(__dir__, "migration")
      end

      def templates
        name = options[:name].to_s.downcase.tr("-", "_")
        found = Dir[File.join(destination_root, "db/migrations/*_#{name}.rb")]
        timestamp = Time.now.to_i
        migration_file = "db/migrations/#{timestamp}_#{name}.rb"

        migration_file = found.first if found.any?

        template "db/migrations/migration.rb.erb", migration_file
      end
    end
  end
end
