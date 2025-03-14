# frozen_string_literal: true

require "test_helper"

class AssetsManifestTest < Minitest::Test
  let(:source) { Pathname("tmp/assets") }
  let(:manifest_path) { source.join(".manifest.json") }
  setup { FileUtils.cp_r("test/fixtures/assets", "tmp/assets") }

  test "creates manifest without digest" do
    manifest = Zee::AssetsManifest.new(source:, digest: false)
    manifest.call

    assert_path_exists manifest_path
    assert_path_exists source.join("images/logo.png")
    assert_path_exists source.join("fonts/font.woff2")
    assert_path_exists source.join("styles/app.css")
    assert_path_exists source.join("scripts/app.js")

    entries = JSON.load_file(manifest_path)

    assert_equal 5, entries.size

    assert_equal "/assets/images/logo.png", entries["images/logo.png"]
    assert_equal "/assets/fonts/font.woff2", entries["fonts/font.woff2"]
    assert_equal "/assets/styles/app.css", entries["styles/app.css"]
    assert_equal "/assets/scripts/app.js", entries["scripts/app.js"]
  end

  test "replaces path references in scripts and styles (no digest)" do
    manifest = Zee::AssetsManifest.new(source:, digest: false)
    manifest.call

    assert_includes File.read(source.join("styles/app.css")),
                    'url("/assets/images/logo.png")'
    assert_includes File.read(source.join("scripts/app.js")),
                    'var logo = "/assets/images/logo.png"'
    assert_includes(
      File.read(source.join("scripts/app.js")),
      "sourceMappingURL=app.js.map"
    )
  end

  test "creates manifest with digest" do
    manifest = Zee::AssetsManifest.new(source:, digest: true)
    manifest.call

    assert_path_exists manifest_path
    assert_path_exists source
      .join("images/logo-20440336743d793e1c584ee061faf1d8.png")
    assert_path_exists source
      .join("fonts/font-0daf79671e01b6ef22bf498e444fe360.woff2")
    assert_path_exists source
      .join("styles/app-a3240ed14fad89b186d34acb7a1a1b78.css")
    assert_path_exists source
      .join("scripts/app-db6a8215764cc81381f488818bf030fa.js")
    assert_path_exists source
      .join("scripts/app-36c6fc9e7604afc6834d6283d8174554.js.map")

    entries = JSON.load_file(manifest_path)

    assert_equal 5, entries.size

    assert_equal "/assets/images/logo-20440336743d793e1c584ee061faf1d8.png",
                 entries["images/logo.png"]
    assert_equal "/assets/fonts/font-0daf79671e01b6ef22bf498e444fe360.woff2",
                 entries["fonts/font.woff2"]
    assert_equal "/assets/styles/app-a3240ed14fad89b186d34acb7a1a1b78.css",
                 entries["styles/app.css"]
    assert_equal "/assets/scripts/app-db6a8215764cc81381f488818bf030fa.js",
                 entries["scripts/app.js"]
    assert_equal "/assets/scripts/app-36c6fc9e7604afc6834d6283d8174554.js.map",
                 entries["scripts/app.js.map"]
    assert_includes \
      source.join("scripts/app-db6a8215764cc81381f488818bf030fa.js").read,
      "sourceMappingURL=#{entries['scripts/app.js.map']}\n"
  end

  test "replaces path references in scripts and styles (with digest)" do
    manifest = Zee::AssetsManifest.new(source:, digest: true)
    manifest.call

    assert_includes(
      File.read(source.join("styles/app-a3240ed14fad89b186d34acb7a1a1b78.css")),
      'url("/assets/images/logo-20440336743d793e1c584ee061faf1d8.png")'
    )
    assert_includes(
      File.read(source.join("scripts/app-db6a8215764cc81381f488818bf030fa.js")),
      'var logo = "/assets/images/logo-20440336743d793e1c584ee061faf1d8.png"'
    )
    assert_includes(
      File.read(source.join("scripts/app-db6a8215764cc81381f488818bf030fa.js")),
      "sourceMappingURL=/assets/scripts/app-36c6fc9e7604afc6834d6283d8174554" \
      ".js.map"
    )
  end
end
