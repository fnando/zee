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
      STYLESHEET = "stylesheet"

      # @api private
      X = "x"

      # @api private
      JS = ".js"

      # @api private
      CSS = ".css"

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
        @_manifest_path ||= Zee.app.root.join(MANIFEST_PATH)
      end

      # Returns the manifest file as a hash.
      # If the manifest file doesn't exist, an empty hash will be returned.
      #
      # ## Manifest format
      #
      # The manifest file is a JSON file that maps the original asset path to
      # the hashed asset path. For example:
      #
      # ```json
      # {
      #   "scripts/app.js": "/assets/scripts/app-hash.js",
      #   "styles/app.css": "/assets/styles/app-hash.css"
      # }
      # ```
      #
      # This file can be generated by the `zee assets` command, usually during
      # your deployment step. The generated manifest file will live
      # at `public/assets/.manifest.json`.
      #
      # @return [Hash]
      def manifest
        if manifest_path.file?
          @_manifest ||= JSON.load_file(manifest_path)
        else
          {}
        end
      end

      # Returns the path to the asset.
      #
      # ## Path resolution
      #
      # - If the source is a string and starts with a slash, then the path will
      #   be used as is.
      # - If the source is a string and starts with `http` or `https`, then the
      #   path will be used as is.
      # - If the source doesn't match the above cases, then it will be resolved
      #   using the manifest file.
      # - If the source is not found in the manifest, then the path will be
      #   prefixed with `/assets`.
      #
      # For all cases where no `http` or `https` is detected, the asset host
      # will be prepended to the path when available. The asset host can be
      # set as `Zee.app.config.set(:asset_host, host)`.
      #
      # You only need to set the host (e.g `example.com`), as the scheme is
      # defined automatically based on the request. You can force it by passing
      # `https://example.com` as the asset host.
      #
      # @param source [String] The source of the asset.
      # @return [String]
      # @param dir [String, nil]
      def asset_path(source, dir: nil)
        source = source.to_s

        return with_asset_host(source) if source.start_with?(SLASH)
        return source if source.match?(/^https?:/)

        source = [dir, source].compact.join(SLASH)

        return with_asset_host(manifest[source]) if manifest[source]

        with_asset_host("/assets/#{source}")
      end

      # @api private
      def with_asset_host(path)
        asset_host = Zee.app.config.asset_host
        asset_host = asset_host.call if asset_host.respond_to?(:call)

        if asset_host
          asset_host = asset_host.delete_suffix(SLASH)
          path = path.delete_prefix(SLASH)

          unless asset_host.match?(/^https?:/)
            scheme = "#{request.env[RACK_URL_SCHEME]}://"
          end

          "#{scheme}#{asset_host}/#{path}"
        else
          path
        end
      end

      # Build a script tag for the given source.
      # @param sources [Array<String, Symbol>] The source of the script. When a
      #                                symbol is given, it will be converted to
      #                                an entrypoint like `"scripts/:source.js`.
      #                                If a string with a leading slash is
      #                                given, then the path will be used as it
      #                                is.
      # @return [SafeBuffer]
      # @see #asset_path #asset_path for path resolution
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
      #
      # @example Passing attributes
      #   javascript_include_tag :app, defer: true
      def javascript_include_tag(*sources, **)
        SafeBuffer.new.tap do |buffer|
          sources.each do |source|
            source = source.to_s
            source = "#{source}#{JS}" unless source.include?(JS)

            path = asset_path(source, dir: SCRIPTS)
            buffer << content_tag(:script, **, src: path)
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
      # @see #asset_path #asset_path for path resolution
      #
      # @example Using a symbol
      #   stylesheet_link_tag :app
      #
      # @example Using a path
      #   stylesheet_link_tag "/some/style.css"
      #
      # @example Using a url
      #   stylesheet_link_tag "https://example.com/style.css"
      def stylesheet_link_tag(*sources, **)
        SafeBuffer.new.tap do |buffer|
          sources.each do |source|
            source = source.to_s
            source = "#{source}#{CSS}" unless source.include?(CSS)

            path = asset_path(source, dir: STYLES)
            buffer << content_tag(:link, rel: STYLESHEET, **, href: path)
          end
        end
      end

      # Build an image tag for the given source.
      #
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
      # @see #asset_path #asset_path for path resolution
      #
      # @example Using a string
      #   image_tag("logo.png")
      #
      # @example Using a path
      #   image_tag("/some/dir/logo.png")
      #
      # @example Using a url
      #   image_tag("https://example.com/logo.png")
      #
      # @example Specifying the image dimensions
      #   image_tag("logo.png", size: 100)
      #   image_tag("logo.png", size: "200x100")
      #
      # @example Using srcset
      #   image_tag("logo.png", srcset: {"logo@2x.png" => "2x"})
      #   image_tag("logo.png", srcset: [["logo@2x.png", "2x"])
      def image_tag(source, alt: nil, size: nil, srcset: nil, **options)
        path = asset_path(source, dir: IMAGES)

        if size
          width, height = size.to_s.split(X)
          options[:width] = width
          options[:height] = height || width
        end

        if srcset
          srcset = srcset.map do |(src, descriptor)|
            "#{asset_path(src, dir: IMAGES)} #{descriptor}"
          end

          options[:srcset] = srcset.join(COMMA_SPACE)
        end

        tag(:img, src: path, alt: alt.to_s, **options)
      end
    end
  end
end
