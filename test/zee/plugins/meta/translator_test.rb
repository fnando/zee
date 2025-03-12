# frozen_string_literal: true

require "test_helper"

module Meta
  class TranslatorTest < Minitest::Test
    test "with controller name" do
      store_translations(
        :en,
        {
          zee: {
            meta: {
              things: {show: {title: "TITLE"}},
              title_base: "%{title} • SITE"
            }
          }
        }
      )

      translator = Zee::Plugins::Meta::Translator.new(
        scope: :title,
        controller_name: "things",
        action_name: "show"
      )

      assert_equal "TITLE • SITE", translator.to_s
      assert_equal "TITLE", translator.text.to_s
    end

    test "without base translation" do
      store_translations :en, {zee: {meta: {things: {show: {title: "TITLE"}}}}}
      translator = Zee::Plugins::Meta::Translator.new(
        scope: :title,
        controller_name: "things",
        action_name: "show"
      )

      assert_equal "TITLE", translator.to_s
      assert_equal "TITLE", translator.text.to_s
    end

    test "with namespaced controller" do
      store_translations(
        :en,
        {
          zee: {
            meta: {admin: {things: {show: {title: "TITLE"}}}}
          }
        }
      )

      translator = Zee::Plugins::Meta::Translator.new(
        scope: :title,
        controller_name: "admin/things",
        action_name: "show"
      )

      assert_equal "TITLE", translator.to_s
    end

    test "with placeholders" do
      store_translations(
        :en,
        {
          zee: {
            meta: {things: {show: {title: "%{title}"}}}
          }
        }
      )

      translator = Zee::Plugins::Meta::Translator.new(
        scope: :title,
        controller_name: "things",
        action_name: "show",
        title: "TITLE"
      )

      assert_equal "TITLE", translator.to_s
    end

    test "with base title placeholders" do
      store_translations(
        :en,
        {
          zee: {
            meta: {
              title_base: "%{title} • %{site_name}",
              things: {show: {title: "%{title}"}}
            }
          }
        }
      )

      translator = Zee::Plugins::Meta::Translator.new(
        scope: :title,
        controller_name: "things",
        action_name: "show",
        title: "TITLE",
        site_name: "My App"
      )

      assert_equal "TITLE • My App", translator.to_s
    end

    test "missing translation" do
      translator = Zee::Plugins::Meta::Translator.new(
        scope: :title,
        controller_name: "things",
        action_name: "show",
        title: "TITLE"
      )

      assert_equal "", translator.to_s
      assert_equal "", translator.text.to_s
    end

    test "with custom base title for action" do
      store_translations(
        :en,
        {
          zee: {
            meta: {
              things: {
                show: {
                  title_base: "%{title} | %{site_name}",
                  title: "TITLE"
                }
              }
            }
          }
        }
      )

      options = {site_name: "SOME SITE"}
      translator = Zee::Plugins::Meta::Translator.new(
        scope: :title,
        controller_name: "things",
        action_name: "show",
        **options
      )

      assert_equal "TITLE | SOME SITE", translator.to_s
      assert_equal "TITLE", translator.text.to_s
    end

    test "with custom base title for controller" do
      store_translations(
        :en,
        {
          zee: {
            meta: {
              things: {
                title_base: "%{title} | %{site_name}",
                show: {
                  title: "TITLE"
                }
              }
            }
          }
        }
      )
      options = {site_name: "SOME SITE"}
      translator = Zee::Plugins::Meta::Translator.new(
        scope: :title,
        controller_name: "things",
        action_name: "show",
        **options
      )

      assert_equal "TITLE | SOME SITE", translator.to_s
      assert_equal "TITLE", translator.text.to_s
    end

    test "returns html translation" do
      store_translations(
        :en,
        {
          zee: {
            meta: {
              things: {
                show: {
                  description_html: "<strong>DESC</strong>"
                }
              }
            }
          }
        }
      )

      translator = Zee::Plugins::Meta::Translator.new(
        scope: :description,
        controller_name: "things",
        action_name: "show",
        title: "TITLE",
        html: true
      )

      assert_equal "<strong>DESC</strong>", translator.to_s
    end

    test "ignores html translation" do
      store_translations(
        :en,
        {
          zee: {
            meta: {
              things: {
                show: {
                  description_html: "<strong>DESC</strong>"
                }
              }
            }
          }
        }
      )

      translator = Zee::Plugins::Meta::Translator.new(
        scope: :description,
        controller_name: "things",
        action_name: "show",
        title: "TITLE"
      )

      assert_equal "", translator.to_s
    end
  end
end
