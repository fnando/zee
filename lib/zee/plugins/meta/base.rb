# frozen_string_literal: true

module Zee
  module Plugins
    module Meta
      class Base
        using Core::Blank

        # @api private
        DEFAULT_VIEWPORT = "width=device-width,initial-scale=1"

        # @api private
        DEFAULT_META_TAGS = %i[
          language
          charset
          title
          viewport
          keywords
          description
        ].freeze

        # @api private
        DEFAULT_ORDER = 99

        # @api private
        META_TAG_ORDER = {
          pragma: -1,
          cache_control: -1,
          expires: -1,
          refresh: -1,
          dns_prefetch_control: 4
        }.freeze

        # @api private
        LINK_ORDER = {
          preconnect: 6,
          preload: 7,
          modulepreload: 8,
          prefetch: 9,
          dns_prefetch: 10
        }.freeze

        attr_reader :controller_name, :action_name, :store, :helpers

        def initialize(controller_name:, action_name:, helpers:)
          @store = {}
          @description = {}
          @controller_name = controller_name
          @action_name = action_name
          @helpers = helpers
        end

        def items
          @items ||= []
        end

        # Delete all matching meta tags by name.
        def delete(name)
          items.delete_if { _1[:name] == name }
        end

        # Set placeholder values for the meta tags.
        def []=(key, value)
          store[key] = value
        end

        # Add a new `<base>` tag.
        def base(href)
          items << {
            type: :tag,
            name: :base,
            value: {href:},
            order: 2,
            open: true
          }
        end

        # Add a new meta tag.
        def tag(name, value = nil, order: nil, **kwargs)
          order = order || META_TAG_ORDER[name] || DEFAULT_ORDER
          items << {type: :meta, name:, value: value || kwargs, order:}
        end

        # Add a new link tag.
        def link(rel, order: nil, **options)
          order = order || LINK_ORDER[rel] || DEFAULT_ORDER
          items << {type: :link, rel:, options:, order:}
        end

        # Add new html tag, like `<base>` or `<title>`.
        def html(name, value, open: false, order: DEFAULT_ORDER)
          items << {type: :tag, name:, order:, open:, value:}
        end

        def render
          compute_default_items
          buffer = SafeBuffer.new

          items.sort_by { _1[:order] }
               .each { buffer << send(:"build_#{_1[:type]}", _1) }

          buffer
        end

        # The title translation.
        def title
          @title ||= Translator.new(
            scope: :title,
            controller_name:,
            action_name:,
            **store
          )
        end

        # The description translation.
        def description(html: false)
          @description[html] ||= Translator.new(
            scope: :description,
            controller_name:,
            action_name:,
            **store,
            html:
          )
        end

        # The keywords translation.
        def keywords
          @keywords ||= Translator.new(
            scope: :keywords,
            controller_name:,
            action_name:, **store
          )
        end

        # @api private
        private def compute_default_items
          DEFAULT_META_TAGS.each do |method_name|
            send(:"compute_default_#{method_name}")
          end
        end

        # @api private
        private def compute_default_language
          tag(:language, I18n.locale)
        end

        # @api private
        private def compute_default_title
          return if title.to_s.blank?

          html(:title, title.to_s, order: 3)
          tag(:title, title)
        end

        # @api private
        private def compute_default_charset
          tag(:charset, Encoding.default_external.name, order: 0)
        end

        # @api private
        private def compute_default_keywords
          tag(:keywords, keywords.to_s) unless keywords.to_s.blank?
        end

        # @api private
        private def compute_default_description
          tag(:description, description.to_s) unless description.to_s.blank?
        end

        # @api private
        private def compute_default_viewport
          return if items.any? { _1[:name] == :viewport && _1[:type] == :tag }

          tag(:viewport, DEFAULT_VIEWPORT, order: 1)
        end

        # @api private
        private def build_meta(item)
          MetaTag.build(name: item[:name], content: item[:value], helpers:)
        end

        # @api private
        private def build_link(item)
          helpers.tag(:link, rel: item[:rel], **item[:options])
        end

        # @api private
        private def build_tag(item)
          value = item.dup.delete(:value)

          if value.is_a?(String)
            content = value
            value = {}
          end

          helpers.tag(item[:name], content, **value)
        end
      end
    end
  end
end
