# frozen_string_literal: true

gem "mail"
require "mail"

module Zee
  class Mailer
    using Core::String
    include Controller::HelperMethods

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

    # @api private
    # The message object.
    def message
      @message ||= ::Mail.new
    end

    # The main method that creates the message and renders the email templates.
    def mail(**options)
      @message = ::Mail.new if options.any?

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
    def assign_body_from_template(name)
      return unless self.class.name

      class_name = self.class.name.underscore.delete_prefix("mailers/")
      templates = Dir["app/views/#{class_name}/#{name}.*"]

      templates.each do |template|
        format = File.basename(template)[/^.*?\.(.*?)\..*?$/, 1]
        content = Zee.app.render_template(template, locals: collect_locals)

        case format
        when "text"
          message.text_part = content
        when "html"
          message.html_part = content
        end
      end
    end
  end
end
