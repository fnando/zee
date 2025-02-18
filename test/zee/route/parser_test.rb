# frozen_string_literal: true

require "test_helper"

class ParserTest < Minitest::Test
  test "inspects segment" do
    segment = Zee::Route::Segment.new(:id, false)

    assert_equal "#<Zee::Route::Segment name=:id optional=false>",
                 segment.inspect
  end

  test "parses root route" do
    parser = Zee::Route::Parser.new("/")

    assert_match parser.matcher, "/"
    assert_empty parser.segments
  end

  test "parses /posts route" do
    parser = Zee::Route::Parser.new("/posts")

    assert_match parser.matcher, "/posts"
    assert_empty parser.segments
  end

  test "parses route with segment" do
    parser = Zee::Route::Parser.new("/posts/:id")

    assert_match parser.matcher, "/posts/1"
    assert_equal 1, parser.segments.size
    assert_equal :id, parser.segments[:id].name
    refute parser.segments[:id].optional?
  end

  test "parses route with optional segment" do
    parser = Zee::Route::Parser.new("/posts(/:id)")

    assert_match parser.matcher, "/posts/1"
    assert_equal 1, parser.segments.size
    assert_equal :id, parser.segments[:id].name
    assert parser.segments[:id].optional?
  end

  test "parses route with optional leading segment" do
    parser = Zee::Route::Parser.new("(/:locale)/posts")

    assert_match parser.matcher, "/posts"
    assert_match parser.matcher, "/en/posts"
    assert_equal 1, parser.segments.size
    assert_equal :locale, parser.segments[:locale].name
    assert parser.segments[:locale].optional?
  end

  test "parses complex path" do
    parser = Zee::Route::Parser.new("(/:locale)/posts/:id(/:action)")

    assert_match parser.matcher, "/posts/1/edit"
    assert_match parser.matcher, "/posts/1"
    assert_match parser.matcher, "/en/posts/1"
    assert_match parser.matcher, "/en/posts/1/edit"
    assert_equal 3, parser.segments.size
    assert_equal :locale, parser.segments[:locale].name
    assert parser.segments[:locale].optional?
  end

  test "builds path for root" do
    parser = Zee::Route::Parser.new("/")

    assert_equal "/", parser.build_path
  end

  test "builds path for /posts" do
    parser = Zee::Route::Parser.new("/posts")

    assert_equal "/posts", parser.build_path
  end

  test "builds path for segment" do
    parser = Zee::Route::Parser.new("/posts/:id")

    assert_equal "/posts/1", parser.build_path(1)
  end

  test "builds path for for optional segment" do
    parser = Zee::Route::Parser.new("/posts(/:id)")

    assert_equal "/posts/1", parser.build_path(1)
    assert_equal "/posts", parser.build_path
  end

  test "builds path for for optional leading segment" do
    parser = Zee::Route::Parser.new("(/:locale)/posts")

    assert_equal "/en/posts", parser.build_path("en")
    assert_equal "/posts", parser.build_path
  end

  test "builds path for for complex route" do
    parser = Zee::Route::Parser.new("(/:locale)/posts(/:id)")

    assert_equal "/en/posts/1", parser.build_path("en", "1")
    assert_equal "/en/posts", parser.build_path("en")
    assert_equal "/posts/1", parser.build_path(nil, "1")
  end

  test "raises for missing required segment" do
    parser = Zee::Route::Parser.new("/posts/:id")

    error = assert_raises(ArgumentError) { parser.build_path }
    assert_equal ":id is required for /posts/:id", error.message
  end
end
