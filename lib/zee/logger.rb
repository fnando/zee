# frozen_string_literal: true

require "logger"

module Zee
  class Logger
    using Core::Blank
    using Core::String::Colored

    # @api private
    LEVELS = {
      debug: ::Logger::DEBUG,
      info: ::Logger::INFO,
      warn: ::Logger::WARN,
      error: ::Logger::ERROR,
      fatal: ::Logger::FATAL,
      unknown: ::Logger::UNKNOWN
    }.freeze

    # @api private
    DEFAULT_FORMATTER = proc do |options|
      line = [options[:tag], options[:message]].reject(&:blank?).join(" ")
      "#{line}\n"
    end

    # @api private
    NO_COLOR = "NO_COLOR"

    # Create a new logger instance.
    #
    # @param logger [::Logger] The logger instance to use.
    # @param formatter [Proc] The formatter to use. Defaults to
    #                         {DEFAULT_FORMATTER}.
    # @param tag [Array<Symbol, String>, nil] tag log tag to use.
    # @param tag_color [Symbol, nil] A color name from
    # @param message_color [Symbol, nil]
    # @param colorize [Boolean] Force color output. Ignores whether the
    #                           output is a TTY or not.
    def initialize(
      logger = ::Logger.new($stdout, level: ::Logger::INFO),
      formatter: DEFAULT_FORMATTER,
      tag: nil,
      tag_color: nil,
      message_color: nil,
      colorize: false
    )
      @logger = logger.dup
      @logger.formatter = proc {|*args| format_log(*args) }
      @tag = Array(tag)
      @formatter = formatter
      @tag_color = tag_color
      @message_color = message_color
      @colorize = colorize
    end

    # Instantiate a new logger with additional tags.
    # This is useful for adding context to log messages.
    #
    # @param tags [Array<Symbol>] The tags to add to the logger.
    # @yieldparam logger [Logger] The new logger instance.
    # @return [Logger]
    #
    # @example Returning an instance
    #   ```ruby
    #   logger = Zee::Logger.new(Logger.new($stdout))
    #   logger.tagged(:app).debug("debug message")
    #   ```
    #
    # @example Using a block
    #   ```ruby
    #   logger = Zee::Logger.new(Logger.new($stdout))
    #   logger.tagged(:app) { _1.debug("debug message") }
    #   ```
    def tagged(*tags, &)
      new_logger = Logger.new(
        @logger,
        formatter: @formatter,
        tag: @tag.dup.concat(tags),
        tag_color: @tag_color,
        message_color: @message_color,
        colorize: @colorize
      )

      yield new_logger if block_given?

      new_logger
    end

    # @api private
    # Format the log message.
    private def format_log(_severity, time, _progname, message)
      tag = @tag.map { "[#{_1}]" }.join

      tag = colorize(tag, @tag_color)
      message = colorize(message, @message_color)

      @formatter.call(message:, tag:, time:)
    end

    # Colorize a string.
    # @param input [String]
    # @param color [Symbol]
    # @return [String]
    def colorize(input, color)
      if @colorize
        input.to_s.colored(color)
      else
        input.to_s
      end
    end

    # @!method debug(message = nil, &block)
    #  Log a debug message.
    #  @param message [String] The message to log.
    #  @yieldreturn [String] The message to log.
    #  @return [Logger]
    #
    # @!method info(message = nil, &block)
    #  Log a info message.
    #  @param message [String] The message to log.
    #  @yieldreturn [String] The message to log.
    #  @return [Logger]
    #
    # @!method warn(message = nil, &block)
    #  Log a warn message.
    #  @param message [String] The message to log.
    #  @yieldreturn [String] The message to log.
    #  @return [Logger]
    #
    # @!method error(message = nil, &block)
    #  Log a error message.
    #  @param message [String] The message to log.
    #  @yieldreturn [String] The message to log.
    #  @return [Logger]
    #
    # @!method fatal(message = nil, &block)
    #  Log a fatal message.
    #  @param message [String] The message to log.
    #  @yieldreturn [String] The message to log.
    #  @return [Logger]
    #
    # @!method unknown(message = nil, &block)
    #  Log a unknown message.
    #  @param message [String] The message to log.
    #  @yieldreturn [String] The message to log.
    #  @return [Logger]
    %i[debug info warn error fatal unknown].each do |name|
      define_method(name) do |message = nil, &block|
        return self if @logger.level > LEVELS[name]

        message ||= block.call if block
        @logger.add(LEVELS[name], message)

        self
      end
    end
  end
end
