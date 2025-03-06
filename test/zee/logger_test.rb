# frozen_string_literal: true

require "test_helper"

class LoggerTest < Minitest::Test
  let(:io) { StringIO.new }

  def io_read(buffer = io)
    buffer.tap(&:rewind).read
  end

  test "logs message to buffer" do
    logger = Zee::Logger.new(Logger.new(io, level: Logger::DEBUG))
    logger.debug "debug message"

    assert_includes io_read, "debug message\n"
  end

  test "logs tag message to buffer" do
    logger = Zee::Logger.new(Logger.new(io, level: Logger::DEBUG), tag: :app)
    logger.debug "debug message"

    assert_includes io_read, "[app] debug message\n"
  end

  test "adds nested tag" do
    logger = Zee::Logger.new(Logger.new(io, level: Logger::DEBUG), tag: :app)
    logger.tagged(:request).debug "nested tagged message"
    logger.tagged(:request) { _1.debug "nested tagged message with block" }
    logger.debug "debug message"

    assert_includes io_read, "[app][request] nested tagged message\n"
    assert_includes io_read, "[app][request] nested tagged message with block\n"
    assert_includes io_read, "[app] debug message\n"
  end

  test "logs colored message to buffer" do
    logger = Logger.new(io, level: Logger::DEBUG)
    logger = Zee::Logger.new(
      logger,
      tag: :app,
      tag_color: :red,
      message_color: :blue,
      colorize: true
    )
    logger.debug "debug message"

    assert_includes io_read(io), "\e[31m[app]\e[0m \e[34mdebug message\e[0m\n"
  end
end
