# frozen_string_literal: true

require "test_helper"

class BlankTest < Minitest::Test
  using Zee::Core::Blank

  test "#blank?" do
    assert "".blank?
    assert "   ".blank?
    assert "\r\n\t   ".blank?
    assert "\u00a0".blank?

    refute "hello".blank?
    refute "  hello ".blank?
    refute "\r\n\t hello  ".blank?

    assert [].blank?
    refute [1].blank?

    assert nil.blank?
    refute 0.blank?
    refute 1.0.blank?
  end

  test "#present?" do
    refute "".present?
    refute "   ".present?
    refute "\r\n\t   ".present?
    refute "\u00a0".present?

    assert "hello".present?
    assert "  hello ".present?
    assert "\r\n\t hello  ".present?

    assert [1].present?
    refute [].present?

    refute nil.present?
    assert 0.present?
    assert 1.0.present?
  end
end
