# frozen_string_literal: true

require "test_helper"

class AssetsTest < Minitest::Test
  let(:helpers) do
    mod = Module.new do
      attr_accessor :request

      include Zee::ViewHelpers::HTML
      include Zee::ViewHelpers::Assets
    end

    Object.new.extend(mod)
  end

  let(:app) { stub(root: Pathname.new("tmp")) }
  setup { Zee.app = app }

  test "returns manifest when file exists" do
    FileUtils.mkdir_p("tmp/public/assets")
    File.write("tmp/public/assets/.manifest.json", JSON.dump(a: "b"))

    assert_equal({"a" => "b"}, helpers.manifest)
  end

  test "returns manifest when file doesn't exist" do
    assert_empty(helpers.manifest)
  end

  test "returns javascript tag using symbol" do
    assert_equal %[<script src="/assets/scripts/app.js"></script>],
                 helpers.javascript_include_tag(:app).to_s
  end

  test "returns javascript tag using attributes" do
    assert_equal %[<script defer src="/assets/scripts/app.js"></script>],
                 helpers.javascript_include_tag(:app, defer: true).to_s
  end

  test "returns javascript tag using arbitrary path" do
    assert_equal %[<script src="/some/script.js"></script>],
                 helpers.javascript_include_tag("/some/script.js").to_s
  end

  test "returns javascript tag from manifest" do
    FileUtils.mkdir_p("tmp/public/assets")
    File.write(
      "tmp/public/assets/.manifest.json",
      JSON.dump("scripts/app.js" => "/assets/scripts/app-hash.js")
    )

    assert_equal %[<script src="/assets/scripts/app-hash.js"></script>],
                 helpers.javascript_include_tag(:app).to_s
  end

  test "returns javascript tag for external scripts" do
    assert_equal \
      %[<script src="https://example.com/script.js"></script>],
      helpers.javascript_include_tag("https://example.com/script.js").to_s
  end

  test "returns stylesheet tag using symbol" do
    assert_equal %[<link rel="stylesheet" href="/assets/styles/app.css">],
                 helpers.stylesheet_link_tag(:app).to_s
  end

  test "returns stylesheet tag using attributes" do
    assert_equal \
      %[<link rel="stylesheet" media="print" href="/assets/styles/print.css">],
      helpers.stylesheet_link_tag(:print, media: "print").to_s
  end

  test "returns stylesheet tag using arbitrary path" do
    assert_equal %[<link rel="stylesheet" href="/some/style.css">],
                 helpers.stylesheet_link_tag("/some/style.css").to_s
  end

  test "returns stylesheet tag for external styles" do
    assert_equal \
      %[<link rel="stylesheet" href="https://example.com/style.css">],
      helpers.stylesheet_link_tag("https://example.com/style.css").to_s
  end

  test "returns stylesheet tag from manifest" do
    FileUtils.mkdir_p("tmp/public/assets")
    File.write(
      "tmp/public/assets/.manifest.json",
      JSON.dump("styles/app.css" => "/assets/styles/app-hash.css")
    )

    assert_equal %[<link rel="stylesheet" href="/assets/styles/app-hash.css">],
                 helpers.stylesheet_link_tag(:app).to_s
  end

  test "returns image tag" do
    assert_equal %[<img src="/assets/images/logo.png" alt="">],
                 helpers.image_tag("logo.png").to_s
  end

  test "returns image tag for external image" do
    assert_equal %[<img src="https://example.com/image.png" alt="">],
                 helpers.image_tag("https://example.com/image.png").to_s
  end

  test "returns image tag with options" do
    assert_equal \
      %[<img src="/assets/images/logo.png" alt="my image" loading="lazy">],
      helpers.image_tag("logo.png", alt: "my image", loading: "lazy").to_s
  end

  test "returns image tag with specified size" do
    assert_equal \
      %[<img src="/assets/images/logo.png" alt="" width="50" height="50">],
      helpers.image_tag("logo.png", size: 50).to_s

    assert_equal \
      %[<img src="/assets/images/logo.png" alt="" width="100" height="50">],
      helpers.image_tag("logo.png", size: "100x50").to_s
  end

  test "returns image tag with srcset" do
    expected_image = "<img src=\"/assets/images/logo.jpg\" " \
                     "alt=\"\" srcset=\"/assets/images/logo@2x.png 2x, " \
                     "/assets/images/logo@3x.png 3x\">"

    assert_equal expected_image,
                 helpers.image_tag("logo.jpg",
                                   srcset: {
                                     "logo@2x.png" => "2x",
                                     "logo@3x.png" => "3x"
                                   }).to_s
    assert_equal expected_image,
                 helpers.image_tag("logo.jpg",
                                   srcset: [
                                     ["logo@2x.png", "2x"],
                                     ["logo@3x.png", "3x"]
                                   ]).to_s
  end

  test "returns image tag using arbitrary path" do
    assert_equal %[<img src="/some/image.png" alt="">],
                 helpers.image_tag("/some/image.png").to_s
  end

  test "returns image tag from manifest" do
    FileUtils.mkdir_p("tmp/public/assets")
    File.write(
      "tmp/public/assets/.manifest.json",
      JSON.dump("images/logo.png" => "/assets/images/logo-hash.png")
    )

    assert_equal %[<img src="/assets/images/logo-hash.png" alt="">],
                 helpers.image_tag("logo.png").to_s
  end
end
