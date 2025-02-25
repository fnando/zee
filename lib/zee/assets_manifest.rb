# frozen_string_literal: true

module Zee
  class AssetsManifest
    # @return [Pathname] the source directories. The relative path will be used
    #                    as the request path.
    attr_reader :source

    # @return [Boolean] whether to digest the assets.
    attr_reader :digest

    # @return [String] a path prefix that will be used to fetch the asset.
    attr_reader :prefix

    # @return [String] the request path format string.
    attr_reader :pattern

    def initialize(source:, digest: true, prefix: "/assets")
      @source = Pathname(source.to_s.delete_suffix("/"))
      @digest = digest
      @prefix = prefix.delete_suffix("/")
      @pattern = if digest
                   "%{prefix}/%{dir}/%{name}-%{digest}.%{extension}"
                 else
                   "%{prefix}/%{dir}/%{name}.%{extension}"
                 end
    end

    def entries
      @entries ||=
        source
        .glob("**/*")
        .filter_map do |path|
          Entry.new(source:, path:, prefix:, pattern:) if path.file?
        end
    end

    def call
      replace_references
      save_manifest
      rename_files
    end

    def rename_files
      return unless digest

      entries.each do |entry|
        to = entry.path.dirname.join(File.basename(entry.request_path))
        entry.path.rename(to)
      end
    end

    def replace_references
      entries.select(&:text_based?).each do |entry|
        contents = entry.path.read

        entries.each do |ref|
          contents.gsub!(%[/assets/#{ref.origin_name}], ref.request_path.to_s)
        end

        if entry.js? && digest
          sourcemaps = entries.find do |other|
            "#{entry.path}.map" == other.path.to_s
          end

          if sourcemaps
            contents.gsub!(
              "sourceMappingURL=#{sourcemaps.path.basename}",
              "sourceMappingURL=#{sourcemaps.request_path}"
            )
          end
        end

        entry.path.write(contents)
      end
    end

    def save_manifest
      data = entries.each_with_object({}) do |entry, buffer|
        buffer[entry.origin_name] = entry.request_path
      end

      File.open(source.join(".manifest.json"), "w+") do |io|
        io << JSON.dump(data)
      end
    end

    class Entry
      attr_reader :source, :path, :prefix, :pattern

      def initialize(source:, path:, prefix:, pattern:)
        @source = source
        @path = path
        @prefix = prefix
        @pattern = pattern
      end

      def js?
        path.basename.to_s.end_with?(".js")
      end

      def digest
        @digest ||= Digest::MD5.hexdigest(path.binread)
      end

      def relative_path
        @relative_path ||= path.relative_path_from(source)
      end

      def relative_dir
        @relative_dir ||= relative_path.dirname
      end

      def origin_name
        relative_path.to_s
      end

      def extension
        @extension ||= path.basename.to_s.split(".")[1..-1].join(".")
      end

      def basename
        @basename ||= path.basename.to_s.split(".").first
      end

      def request_path
        @request_path ||= begin
          dir = relative_dir.to_s == "." ? "" : relative_dir.to_s
          path = format(
            pattern,
            prefix:,
            dir:,
            name: basename,
            digest:,
            extension:
          ).split("/").reject(&:empty?).join("/")

          "/#{path}"
        end
      end

      def text_based?
        path.extname.match?(/\.(js|css)$/)
      end
    end
  end
end
