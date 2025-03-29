# frozen_string_literal: true

module Zee
  module CLI
    class Root < Command
      desc "assets", "Build assets"
      option :digest,
             type: :boolean,
             default: true,
             desc: "Enable asset digesting"
      option :prefix,
             type: :string,
             default: "/assets",
             desc: "The request path prefix"
      def assets
        bins = %w[bin/styles bin/scripts]

        FileUtils.rm_rf("public/assets")
        FileUtils.mkdir_p("public/assets")

        bins.each do |bin|
          bin = Pathname(bin)

          unless bin.file?
            raise Thor::Error,
                  set_color("ERROR: #{bin} not found", :red)
          end

          unless bin.executable?
            raise Thor::Error,
                  set_color("ERROR: #{bin} is not executable", :red)
          end

          # Export styles and scripts
          unless system(bin.to_s)
            raise Thor::Error, set_color("ERROR: #{bin} failed to run", :red)
          end
        end

        # Copy other assets
        Dir["./app/assets/*"].each do |dir|
          next if dir.end_with?("styles", "scripts")

          FileUtils.cp_r(dir, "public/assets/")
        end

        AssetsManifest.new(
          source: Pathname(Dir.pwd).join("public/assets"),
          digest: options[:digest],
          prefix: options[:prefix]
        ).call
      end
    end
  end
end
