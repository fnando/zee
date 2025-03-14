# frozen_string_literal: true

require "test_helper"

class ActionAliasTest < Minitest::Test
  test "map default alias - update" do
    action = Zee::Plugins::Meta::ActionAlias.new("update")

    assert_equal "edit", action.to_s
  end

  test "map default alias - create" do
    action = Zee::Plugins::Meta::ActionAlias.new("create")

    assert_equal "new", action.to_s
  end

  test "map default alias - destroy" do
    action = Zee::Plugins::Meta::ActionAlias.new("destroy")

    assert_equal "remove", action.to_s
  end

  test "define new alias" do
    Zee::Plugins::Meta::ActionAlias.aliases["landing"] = "home"
    action = Zee::Plugins::Meta::ActionAlias.new("landing")

    assert_equal "home", action.to_s
    Zee::Plugins::Meta::ActionAlias.aliases.delete("landing")
  end
end
