# frozen_string_literal: true

module Zee
  module ViewHelpers
    module Assets
      # @api private
      TYPE_TO_DIR_MAPPING = {
        js: "scripts",
        css: "styles",
        font: "fonts",
        image: "images"
      }.freeze

      # @api private
      JS = "js"

      # @api private
      CSS = "css"

      # @api private
      STYLES = "styles"

      # @api private
      IMAGES = "images"

      # @api private
      SCRIPTS = "scripts"

      # @api private
      MANIFEST_PATH = "public/assets/.manifest.json"

      # Return the path to the manifest file.
      # @return [Pathname]
      def manifest_path
        @manifest_path ||= Zee.app.root.join(MANIFEST_PATH)
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
      # @param source [String] The source of the asset.
      # @return [String]
      def assets_path(source)
        source = source.to_s

        return manifest[source] if manifest[source]

        source = "/assets/#{source}" unless source.start_with?(SLASH)
        source
      end

      # Convert the given source to an asset path.
      # @param ext [String] The extension of the asset.
      # @param source [String, Symbol] The source of the asset.
      # @param dir [String] The directory where the asset is located.
      # @return [String]
      def to_assets_path(ext:, source:, dir:)
        source = source.to_s
        return source if source.start_with?(SLASH)

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
            path = to_assets_path(ext: JS, source:, dir: SCRIPTS)
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
            path = to_assets_path(ext: CSS, source:, dir: STYLES)
            buffer << SafeBuffer.new(%[<link rel="stylesheet" href="#{path}">])
          end
        end
      end

      # Build an image tag for the given source.
      # @param source [String] The source of the image.
      # @param alt [String] The alt text for the image.
      # @param size [String] The image dimensions. If a string like `100x50` is
      #                      given, then the width will be set to `100` and the
      #                      height to `50`. If only a number is given, then the
      #                      width and height will be set to that number.
      # @param srcset [Hash, Array] If supplied as a hash or array of
      #                             `[source, descriptor]` pairs, each image
      #                             path will be expanded before the list is
      #                             formatted as a string.
      # @param options [Hash{Symbol => Object}] Additional options for the
      #                                         image.
      # @return [SafeBuffer]
      #
      # @example
      #   <%= image_tag("logo.png") %>
      def image_tag(source, alt: nil, size: nil, srcset: nil, **options)
        ext = File.extname(source).delete_prefix(DOT)
        path = to_assets_path(ext:, source:, dir: IMAGES)

        if size
          width, height = size.to_s.split("x")
          options[:width] = width
          options[:height] = height || width
        end

        if srcset
          srcset = srcset.map do |(src, descriptor)|
            ext = File.extname(src).delete_prefix(DOT)
            src = to_assets_path(ext: ext, source: src, dir: IMAGES)
            "#{src} #{descriptor}"
          end

          options[:srcset] = srcset.join(COMMA_SPACE)
        end

        tag(:img, src: path, alt: alt.to_s, **options)
      end
    end
  end
end
