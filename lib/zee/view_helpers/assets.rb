# frozen_string_literal: true

module Zee
  module ViewHelpers
    module Assets
      # @private
      TYPE_TO_DIR_MAPPING = {
        js: "scripts",
        css: "styles",
        font: "fonts",
        image: "images"
      }.freeze

      # Return the path to the manifest file.
      # @return [Pathname]
      def manifest_path
        @manifest_path ||= request.env[RACK_ZEE_APP]
                                  .root
                                  .join("public/assets/.manifest.json")
      end

      # Returns the manifest file as a hash.
      # If the manifest file doesn't exist, an empty hash will be returned.
      # @return [Hash]
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

      # Build a script tag for the given source.
      # @param sources [Array<String, Symbol>] The source of the script. When a
      #                                symbol is given, it will be converted to
      #                                an entrypoint like `"scripts/:source.js`.
      #                                If a string with a leading slash is
      #                                given, then the path will be used as it
      #                                is.
      # @return [SafeBuffer]
      #
      # @example Using a symbol
      #   javascript_include_tag :app
      #
      # @example Using multiple symbols
      #   javascript_include_tag :reset, :app
      #
      # @example Using a path
      #   javascript_include_tag "/some/script.js"
      #
      # @example Using a url
      #   javascript_include_tag "https://example.com/script.js"
      def javascript_include_tag(*sources)
        SafeBuffer.new.tap do |buffer|
          sources.each do |source|
            path = to_assets_path(ext: "js", source:, dir: "scripts")
            buffer << SafeBuffer.new(%[<script src="#{path}"></script>])
          end
        end
      end

      # Build a link tag for the given source.
      # @param sources [Array<String, Symbol>] The source of the stylesheet.
      #                                When a symbol is given, it will be
      #                                converted to an entrypoint like
      #                                `"scripts/:source.js`. If a string with a
      #                                leading slash is given, then the path
      #                                will be used as it is.
      # @return [SafeBuffer]
      #
      # @example Using a symbol
      #   stylesheet_link_tag :app
      #
      # @example Using a path
      #   stylesheet_link_tag "/some/style.css"
      #
      # @example Using a url
      #   stylesheet_link_tag "https://example.com/style.css"
      def stylesheet_link_tag(*sources)
        SafeBuffer.new.tap do |buffer|
          sources.each do |source|
            path = to_assets_path(ext: "css", source:, dir: "styles")
            buffer << SafeBuffer.new(%[<link rel="stylesheet" href="#{path}">])
          end
        end
      end
    end
  end
end
