# frozen_string_literal: true

module Zee
  class FormBuilder
    # @return [Object] the object to be used as the form's data source.
    attr_reader :object

    # @return [String] the form's name.
    attr_reader :as

    # @return [Hash] additional options.
    attr_reader :options

    # @return [String] the form's action URL.
    attr_reader :url

    # @return [Proc] the block to evaluate within the form.
    attr_reader :block

    # @return [Layout] the form's layout.
    attr_reader :layout

    # @param object [Object] the object to be used as the form's data source.
    # @param url [String] the form's action URL.
    # @param as [Symbol] the form's name.
    # @param layout [Layout] Set the form layout.
    # @param options [Hash{Symbol => Object}] additional options.
    # @option options [String] :enctype the form's enctype.
    # @option options [String] :id the form's ID.
    # @option options [String] :method the form's method. Defaults to `POST`.
    # @param block [Proc] the block to evaluate within the form.
    def initialize(object:, url:, as: nil, layout: Layout, **options, &block)
      @object = object
      @as = as
      @url = url
      @layout = layout
      @options = options
      @options[:method] ||= :post
      @block = block
    end

    # @private
    # Render the form.
    def call
      form = Form.new(builder: self)
      form.call { form.instance_eval(&block) if block }
    end
  end
end
