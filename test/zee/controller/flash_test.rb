# frozen_string_literal: true

require "test_helper"

class FlashTest < Minitest::Test
  let(:session) { {} }
  let(:flash) { Zee::Controller::Flash::FlashHash.new(session) }

  test "iterates flash messages" do
    flash.notice = "notice message"
    flash.alert = "alert message"

    messages = {}

    flash.each do |key, value|
      messages[key] = value
    end

    assert_equal({notice: "notice message", alert: "alert message"}, messages)
  end

  test "clears messages" do
    flash.notice = "notice message"
    flash.alert = "alert message"

    flash.clear

    assert_empty flash
  end

  test "discards message" do
    flash.notice = "message"
    flash.discard(:notice)

    assert_equal [:notice], session[:flash][:discard]
  end

  test "deletes message" do
    flash.notice = "message"
    flash.discard(:notice)
    flash.delete(:notice)

    assert_empty session[:flash][:discard]
    assert_empty session[:flash][:messages]
  end

  test "sets notice" do
    flash.notice = "notice message"

    assert_equal "notice message", flash[:notice]
    assert_equal "notice message", flash.notice
    refute_empty flash
    assert flash.any?
  end

  test "sets alert" do
    flash.alert = "alert message"

    assert_equal "alert message", flash[:alert]
    assert_equal "alert message", flash.alert
  end

  test "sets error" do
    flash.error = "error message"

    assert_equal "error message", flash[:error]
    assert_equal "error message", flash.error
  end

  test "sets info" do
    flash.info = "info message"

    assert_equal "info message", flash[:info]
    assert_equal "info message", flash.info
  end

  test "sets notice for current action" do
    flash.now.notice = "notice message"

    assert_equal "notice message", flash.notice
    assert_equal [:notice], session[:flash][:discard]
  end

  test "sets alert for current action" do
    flash.now.alert = "alert message"

    assert_equal "alert message", flash.alert
    assert_equal [:alert], session[:flash][:discard]
  end

  test "sets info for current action" do
    flash.now.info = "info message"

    assert_equal "info message", flash.info
    assert_equal [:info], session[:flash][:discard]
  end

  test "sets error for current action" do
    flash.now.error = "error message"

    assert_equal "error message", flash.error
    assert_equal [:error], session[:flash][:discard]
  end
end
