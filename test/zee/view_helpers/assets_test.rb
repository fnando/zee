# frozen_string_literal: true

require "test_helper"

class AssetsTest < Minitest::Test
  let(:helpers) do
    mod = Module.new do
      attr_accessor :request

      include Zee::ViewHelpers::Assets
    end

    Object.new.extend(mod)
  end

  test "returns manifest when file exists" do
    FileUtils.mkdir_p("tmp/public/assets")
    File.write("tmp/public/assets/.manifest.json", JSON.dump(a: "b"))
    app = stub(root: Pathname.new("tmp"))
    helpers.request = Zee::Request.new({"zee.app" => app})

    assert_equal({"a" => "b"}, helpers.manifest)
  end

  test "returns manifest when file doesn't exist" do
    app = stub(root: Pathname.new("tmp"))
    helpers.request = Zee::Request.new({"zee.app" => app})

    assert_empty(helpers.manifest)
  end

  test "returns javascript tag using symbol" do
    app = stub(root: Pathname.new("tmp"))
    helpers.request = Zee::Request.new({"zee.app" => app})

    assert_equal %[<script src="/assets/scripts/app.js"></script>],
                 helpers.javascript_include_tag(:app).to_s
  end

  test "returns javascript tag using arbitrary path" do
    app = stub(root: Pathname.new("tmp"))
    helpers.request = Zee::Request.new({"zee.app" => app})

    assert_equal %[<script src="/some/script.js"></script>],
                 helpers.javascript_include_tag("/some/script.js").to_s
  end

  test "returns javascript tag from manifest" do
    FileUtils.mkdir_p("tmp/public/assets")
    File.write(
      "tmp/public/assets/.manifest.json",
      JSON.dump("scripts/app.js" => "/assets/scripts/app-hash.js")
    )
    app = stub(root: Pathname.new("tmp"))
    helpers.request = Zee::Request.new({"zee.app" => app})

    assert_equal %[<script src="/assets/scripts/app-hash.js"></script>],
                 helpers.javascript_include_tag(:app).to_s
  end

  test "returns stylesheet tag using symbol" do
    app = stub(root: Pathname.new("tmp"))
    helpers.request = Zee::Request.new({"zee.app" => app})

    assert_equal %[<link rel="stylesheet" href="/assets/styles/app.css">],
                 helpers.stylesheet_link_tag(:app).to_s
  end

  test "returns stylesheet tag using arbitrary path" do
    app = stub(root: Pathname.new("tmp"))
    helpers.request = Zee::Request.new({"zee.app" => app})

    assert_equal %[<link rel="stylesheet" href="/some/style.css">],
                 helpers.stylesheet_link_tag("/some/style.css").to_s
  end

  test "returns stylesheet tag from manifest" do
    FileUtils.mkdir_p("tmp/public/assets")
    File.write(
      "tmp/public/assets/.manifest.json",
      JSON.dump("styles/app.css" => "/assets/styles/app-hash.css")
    )
    app = stub(root: Pathname.new("tmp"))
    helpers.request = Zee::Request.new({"zee.app" => app})

    assert_equal %[<link rel="stylesheet" href="/assets/styles/app-hash.css">],
                 helpers.stylesheet_link_tag(:app).to_s
  end
end
