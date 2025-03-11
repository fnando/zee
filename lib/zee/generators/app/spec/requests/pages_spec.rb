# frozen_string_literal: true

require "spec_helper"

# Request specs use Rack::Test to simulate HTTP requests to the application.
# They are faster than feature specs, but they are less realistic and don't
# support JavaScript. By default, request specs are tagged with `type :request`.
RSpec.describe "Pages" do
  it "renders the home page" do
    get "/"

    expect(last_response.status).to eq(200)
    expect(last_response).to be_ok
  end
end
