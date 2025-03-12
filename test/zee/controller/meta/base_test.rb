# frozen_string_literal: true

require "test_helper"

module Meta
  class BaseTest < Minitest::Test
    include Zee::Test::Assertions::HTML

    let(:meta) do
      Zee::Controller::Meta::Base.new(
        controller_name: "pages",
        action_name: "show",
        helpers: Object.new.extend(Zee.app.helpers)
      )
    end

    setup do
      store_translations :en,
                         zee: {
                           meta: {
                             title_base: "%{title} • Dummy",
                             pages: {
                               show: {
                                 title: "Show Page"
                               }
                             }
                           }
                         }

      meta.base "http://example.com/"
      meta.tag :author, "John Doe"
      meta.tag :robots, "index, follow"
      meta.tag :copyright, "ACME"
      meta.tag :pragma, "no-cache"
      meta.tag :description, "DESCRIPTION"
      meta.tag :dns_prefetch_control, "http://example.com"
      meta.tag :keywords, "KEYWORDS"

      meta.tag :og,
               image: "IMAGE",
               image_type: "image/jpeg",
               image_width: 800,
               image_height: 600,
               description: "DESCRIPTION",
               title: "TITLE",
               type: "article",
               article_author: "John Doe",
               article_section: "Getting Started",
               url: "URL"

      meta.tag :twitter,
               card: "summary",
               site: "@johndoe",
               domain: "DOMAIN",
               image: "IMAGE",
               creator: "@marydoe"

      meta.tag :some_proc, -> { "proc value" }

      meta.link :preconnect, href: "http://assets.example.com/"
      meta.link :preload, href: "style.css", as: "style"
      meta.link :modulepreload, href: "main.js"
      meta.link :prefetch, href: "main.js"
      meta.link :last, href: "/pages/last"
      meta.link :first, href: "/pages/first"
      meta.link :next, href: "/pages/next"
      meta.link :previous, href: "/pages/previous"
      meta.link :fluid_icon, type: "image/png", href: "fluid.icon"

      meta.link :apple_touch_icon,
                sizes: "512x512",
                href: "/launcher-512.png"
      meta.link :apple_touch_icon,
                sizes: "1024x1024",
                href: "/launcher-1024.png"
    end

    test "renders most important tags first" do
      meta.items.shuffle!
      html = Nokogiri::HTML.fragment(meta.render.to_s)

      assert_equal %[<meta http-equiv="pragma" content="no-cache">],
                   html.children[0].to_s

      assert_equal %[<meta charset="UTF-8">], html.children[1].to_s

      assert_equal \
        %[<meta name="viewport" content="width=device-width,initial-scale=1">],
        html.children[2].to_s

      assert_equal %[<base href="http://example.com/">], html.children[3].to_s

      assert_equal %[<title>Show Page • Dummy</title>], html.children[4].to_s

      assert_equal %[<meta http-equiv="x-dns-prefetch-control" content="on">] +
                   %[<link rel="dns-prefetch" href="http://example.com">],
                   html.children[5..6].to_s

      assert_equal %[<link rel="preconnect" href="http://assets.example.com/">],
                   html.children[7].to_s

      assert_equal %[<link rel="preload" href="style.css" as="style">],
                   html.children[8].to_s

      assert_equal %[<link rel="modulepreload" href="main.js">],
                   html.children[9].to_s

      assert_equal %[<link rel="prefetch" href="main.js">],
                   html.children[10].to_s
    end

    test "renders language tags" do
      html = Nokogiri::HTML.fragment(meta.render.to_s)

      assert_selector html, "meta[name=language][content=en]"
      assert_selector html, "meta[itemprop=language][content=en]"
    end

    test "renders title meta tags" do
      html = Nokogiri::HTML.fragment(meta.render.to_s)

      assert_selector html, "meta[name='DC.title'][content='Show Page • Dummy']"
      assert_selector html, "meta[itemprop=name][content='Show Page • Dummy']"
    end

    test "renders og meta tags" do
      html = Nokogiri::HTML.fragment(meta.render.to_s)

      assert_selector html, %[meta[property="og:image"][content="IMAGE"]]
      assert_selector html,
                      %[meta[property="og:image:type"][content="image/jpeg"]]
      assert_selector html, %[meta[property="og:image:width"][content=800]]
      assert_selector html, %[meta[property="og:image:height"][content=600]]
      assert_selector html,
                      %[meta[property="og:description"][content="DESCRIPTION"]]
      assert_selector html, %[meta[property="og:title"][content="TITLE"]]
      assert_selector html, %[meta[property="og:type"][content="article"]]
      assert_selector html,
                      %[meta[property="og:article:author"][content="John Doe"]]
      assert_selector \
        html,
        %[meta[property="og:article:section"][content="Getting Started"]]
      assert_selector html, %[meta[property="og:url"][content="URL"]]
    end

    test "renders twitter meta tags" do
      html = Nokogiri::HTML.fragment(meta.render.to_s)

      assert_selector html, %[meta[property="twitter:card"][content="summary"]]
      assert_selector html, %[meta[property="twitter:site"][content="@johndoe"]]
      assert_selector html, %[meta[property="twitter:domain"][content="DOMAIN"]]
      assert_selector html, %[meta[property="twitter:image"][content="IMAGE"]]
      assert_selector html,
                      %[meta[property="twitter:creator"][content="@marydoe"]]
    end

    test "renders meta with proc as content" do
      html = Nokogiri::HTML.fragment(meta.render.to_s)

      assert_selector html, %[meta[name="some-proc"][content="proc value"]]
    end

    test "deletes tags by name" do
      meta.delete(:description)

      html = Nokogiri::HTML.fragment(meta.render.to_s)

      assert_selector html, %[meta[name="description"]], count: 0
    end

    test "sets values" do
      store_translations(
        :en,
        zee: {
          meta: {
            title_base: "%{title} • Dummy",
            pages: {
              show: {
                title: "%{post_title}"
              }
            }
          }
        }
      )

      meta.delete(:title)
      meta[:post_title] = "Some post"

      html = Nokogiri::HTML.fragment(meta.render.to_s)

      assert_selector html, %[title], text: /Some post/
    end
  end
end
