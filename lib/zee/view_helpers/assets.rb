# frozen_string_literal: true

module Zee
  module ViewHelpers
    module Assets
      TYPE_TO_DIR_MAPPING = {
        js: "scripts",
        css: "styles",
        font: "fonts",
        image: "images"
      }.freeze

      def manifest_path
        @manifest_path ||= request.env[RACK_ZEE_APP]
                                  .root
                                  .join("public/assets/.manifest.json")
      end

      def manifest
        if manifest_path.file?
          @manifest ||= JSON.load_file(manifest_path)
        else
          {}
        end
      end

      # Returns the path to the asset.
      def assets_path(source)
        source = source.to_s

        return manifest[source] if manifest[source]

        source = "/assets/#{source}" unless source.start_with?("/")
        source
      end

      def to_assets_path(ext:, source:, dir:)
        source = source.to_s
        return source if source.start_with?("/")

        source = "#{dir}/#{source}" unless source.include?("#{dir}/")
        source = "#{source}.#{ext}" unless source.end_with?(".#{ext}")

        assets_path(source)
      end

      def javascript_include_tag(*sources)
        (+"").tap do |io|
          sources.each do |source|
            path = to_assets_path(ext: "js", source:, dir: "scripts")
            io << %[<script src="#{path}"></script>]
          end
        end
      end

      def stylesheet_link_tag(*sources)
        (+"").tap do |io|
          sources.each do |source|
            path = to_assets_path(ext: "css", source:, dir: "styles")
            io << %[<link rel="stylesheet" href="#{path}">]
          end
        end
      end
    end
  end
end
