# frozen_string_literal: true

module Zee
  class Template
    # @api private
    # Identifies the template path+mime that's used to render partials.
    Info = Data.define(:path, :mime)

    def self.cache
      @cache ||= {}
    end

    def self.render(
      file,
      locals: {},
      context: nil,
      controller: nil,
      request: nil,
      helpers: Module.new,
      cache: false,
      use_safe_buffer: true,
      &
    )
      template_path = Pathname(file)
      context ||= Object.new.extend(helpers)
      context.instance_variable_set(:@_controller, controller)
      context.instance_variable_set(:@_request, request)

      cache_key = template_path.to_s
      template = self.cache[cache_key]

      vars = locals.each_with_object({}) do |(key, value), buffer|
        if key.start_with?(AT_SIGN)
          context.instance_variable_set(key, value)
        else
          buffer[key] = value
        end
      end

      unless template
        engine_class = if use_safe_buffer
                         # This is zee's SafeBuffer class
                         Erubi::CaptureBlockEngine
                       else
                         # This is erubi's CaptureBlockEngine class
                         ::Erubi::CaptureBlockEngine
                       end

        options = {
          engine_class:,
          freeze_template_literals: false,
          escape: use_safe_buffer,
          bufval: BUFVAL,
          bufvar: BUFVAR
        }

        template = Tilt.new(file, options)
        self.cache[cache_key] = template if cache
      end

      context.instance_variable_set(
        :@_current_template,
        Template.new(template_path, template)
      )

      template.render(context, vars, &)
    end

    # Return the current template path.
    #
    # @return [Pathname]
    attr_reader :path

    def initialize(path, compiled_template)
      @path = Pathname(path)
      @compiled_template = compiled_template
    end

    def digest
      @digest ||= Digest::MD5.hexdigest(@compiled_template.data)
    end

    def cache_key
      @cache_key ||= [:views, digest].join(COLON)
    end
  end
end
