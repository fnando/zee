# frozen_string_literal: true

module Zee
  class Controller
    module Meta
      # @api private
      class MetaTag
        using Core::String
        using Core::Blank

        attr_reader :name, :helpers

        def self.build(name:, content:, helpers:)
          klass = begin
            const_get(name.to_s.camelize)
          rescue NameError
            MetaTag
          end
          klass.new(name:, content:, helpers:).render
        end

        def initialize(name:, content:, helpers:)
          @name = name.to_s.dasherize
          @raw_content = content
          @helpers = helpers
        end

        def content
          @content ||= if @raw_content.respond_to?(:call)
                         @raw_content.call
                       else
                         @raw_content
                       end
        end

        def render
          helpers.tag(:meta, name:, content:) unless content.blank?
        end

        class Charset < MetaTag
          def render
            return if content.blank?

            helpers.tag(:meta, charset: content)
          end
        end

        class Title < MetaTag
          def render
            helpers.tag(:meta, name: "DC.title", content: content) +
              helpers.tag(:meta, itemprop: "name", content: content)
          end
        end

        class HashMetaTag < MetaTag
          def render
            return if content.empty?

            content.each_with_object(SafeBuffer.new) do |(attr, value), buffer|
              value = value.call if value.respond_to?(:call)
              value = value.to_s

              next if value.blank?

              attr = attr.to_s.tr("_", ":")

              buffer << helpers.tag(
                :meta,
                property: "#{base_name}:#{attr}",
                content: value
              )
            end
          end
        end

        class Og < HashMetaTag
          def base_name
            "og"
          end
        end

        class Twitter < HashMetaTag
          def base_name
            "twitter"
          end
        end

        class DnsPrefetchControl < MetaTag
          def render
            meta = helpers.tag(
              :meta,
              "http-equiv" => "x-dns-prefetch-control",
              content: "on"
            )

            link = helpers.tag(:link, rel: "dns-prefetch", href: content)

            meta + link
          end
        end

        class Language < MetaTag
          def render
            helpers.tag(:meta, name:, content:) +
              helpers.tag(:meta, itemprop: name, content:)
          end
        end

        class MultipleMetaTag < MetaTag
          def render
            return if content.blank?

            helpers.tag(:meta, name:, content:) +
              helpers.tag(:meta, itemprop: name, content:)
          end
        end

        class HttpEquiv < MetaTag
          def render
            return if content.blank?

            helpers.tag(:meta, "http-equiv" => name, content:)
          end
        end

        class Description < MultipleMetaTag; end
        class Author < MultipleMetaTag; end
        class Keywords < MultipleMetaTag; end

        class Pragma < HttpEquiv; end
        class CacheControl < HttpEquiv; end
        class Imagetoolbar < HttpEquiv; end
        class Expires < HttpEquiv; end
        class Refresh < HttpEquiv; end
      end
    end
  end
end
