# frozen_string_literal: true

gem "mail"
require "mail"

module Zee
  class Mailer
    using Core::String
    using Core::Blank
    include Controller::HelperMethods
    include Controller::Renderer
    include Instrumentation

    # Raised when a template is missing.
    MissingTemplateError = Class.new(StandardError)

    # @api private
    MAILER = "mailer"

    # @api private
    MAILERS_PREFIX = "mailers/"

    # @api private
    MAILERS_CLASS_PREFIX = "Mailers"

    # @api private
    def self.method_missing(name, *, **)
      if respond_to_missing?(name)
        new.process_email(name, *, **)
      else
        super
      end
    end

    # @api private
    def self.respond_to_missing?(name, _all = true)
      instance_methods.include?(name)
    end

    def self.naming
      @naming ||= Naming::Name.new(name, prefix: MAILERS_CLASS_PREFIX)
    end

    # @api private
    # The message object.
    def message
      @message ||= build_new_message
    end

    # @api private
    def build_new_message
      Message.new("#{controller_name}##{action_name}")
    end

    # @api private
    def controller_name
      self.class.naming.underscore
    end

    # @api private
    def action_name
      @_action_name
    end

    # @api private
    def mailer_name
      "#{controller_name}##{action_name}"
    end

    # @api private
    def translation_for(scope)
      I18n.t(
        scope,
        scope: [:zee, :mailers, controller_name, action_name],
        default: nil
      )
    end

    # The main method that creates the message and renders the email templates.
    def mail(**options)
      @message = build_new_message if options.any?

      options[:subject] ||= translation_for(:subject)

      assign_headers(options.delete(:headers) || {})
      assign_attachments(options.delete(:attachments) || {})
      assign_body(options.delete(:type), options.delete(:body))
      assign_other_options(options)

      message
    end

    # @api private
    def assign_body(type, content)
      content = content.to_s

      return if content.empty?

      case type
      when :html
        message.html_part = content.to_s
      else
        message.text_part = content.to_s
      end
    end

    # @api private
    def assign_other_options(options)
      options.each {|key, value| message[key] = value }
    end

    # @api private
    def assign_headers(headers)
      headers.each do |key, value|
        message.header[key.to_s.tr(UNDERSCORE, DASH)] = value
      end
    end

    # @api private
    def assign_attachments(attachments)
      attachments.each do |filename, content|
        message.add_file(filename:, content:)
      end
    end

    # @api private
    def process_email(name, *, **)
      @_action_name = name
      send(name, *, **)

      if message.parts.reject(&:attachment?).empty?
        assign_body_from_template(name)
      end

      message
    end

    # @api private
    def collect_locals
      instance_variables.each_with_object({}) do |name, buffer|
        buffer[name] = instance_variable_get(name)
      end
    end

    # @api private
    private def name_ancestry
      names =
        self
        .class
        .ancestors
        .filter_map do |klass|
          klass.is_a?(Class) &&
            klass < Zee::Mailer &&
            klass.name.present? &&
            klass.name.underscore.delete_prefix(MAILERS_PREFIX)
        end

      (names + [MAILER]).uniq
    end

    # @api private
    def view_paths
      Zee.app.view_paths
    end

    # @api private
    def render(name, mimes:, locals:)
      template = find_template(name, mimes, required: false)
      return unless template

      response.view = template
      locals = locals.merge(:@_response => response, :@_controller => self)

      use_safe_buffer = mimes.any? {|mime| mime.content_type == TEXT_HTML }
      layout = find_layout(nil, mimes)
      content = instrument(
        :mailer,
        scope: :view,
        path: template.path,
        mailer: mailer_name
      ) do
        Zee.app.render_template(template.path, locals:, use_safe_buffer:)
      end

      if layout
        content = instrument(
          :mailer,
          scope: :layout,
          path: layout.path,
          mailer: mailer_name
        ) do
          Zee.app.render_template(layout.path, locals:) do
            SafeBuffer.new(content)
          end
        end
      end

      content
    end

    # @api private
    def response
      @response ||= Response.new
    end

    # @api private
    def assign_body_from_template(name)
      return unless self.class.name

      locals = collect_locals

      text_part = render(
        name,
        mimes: [MiniMime.lookup_by_content_type(TEXT_PLAIN)],
        locals:
      )
      html_part = render(
        name,
        mimes: [MiniMime.lookup_by_content_type(TEXT_HTML)],
        locals:
      )

      message.text_part = text_part if text_part
      message.html_part = html_part if html_part

      return if text_part || html_part

      raise MissingTemplateError,
            "couldn't find template for #{self.class.naming.underscore}##{name}"
    end

    # @api private
    def routes
      @routes ||= Object.extend(Zee.app.routes.helpers)
    end

    # @api private
    def method_missing(name, *, **, &)
      return routes.public_send(name, *, **) if routes.respond_to?(name)

      super
    end

    # @api private
    def respond_to_missing?(name, *)
      routes.respond_to?(name) || super
    end
  end
end
