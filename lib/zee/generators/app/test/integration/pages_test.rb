# frozen_string_literal: true

module Integration
  class PagesTest < Zee::Test::Integration
    # Uncomment this line to use JavaScript in the test.
    # It's slower, and requires
    # [chromedriver](https://googlechromelabs.github.io/chrome-for-testing/#stable).
    # use_javascript!

    test "renders home page" do
      visit "/"

      assert_equal 200, page.status_code
      assert_selector page.body, "li:nth-child(1)", text: /Zee version:/
    end
  end
end
