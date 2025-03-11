# frozen_string_literal: true

require "spec_helper"

# Feature specs use Capybara to simulate user interactions with the application.
# They are slower than request specs, but they are more realistic.
# By default, feature specs are tagged with `type :feature`.
#
# To run a JavaScript driver, set your `describe` with `js: true`. Notice that
# you must have an app running at `localhost:3000`.
RSpec.describe "Home" do
  it "renders the home page" do
    visit "/"

    expect(page).to have_current_path("/")
    expect(page).to have_selector("li>strong", count: 3)
  end
end
