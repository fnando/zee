# frozen_string_literal: true

# SampleApp = Dir.chdir(__dir__) do
SampleApp = Zee::App.new do
  self.root = Pathname(__dir__)

  routes do
    root to: "pages#home"
    get "missing-template", to: "pages#missing_template"
    get "hello", to: "pages#hello"
    get "text", to: "formats#text"
    post "session", to: "sessions#create"
    get "session", to: "sessions#show"
    delete "session", to: "sessions#delete"
  end

  middleware do
    delete Rack::CommonLogger

    use Rack::Session::Cookie,
        key: Zee::ZEE_SESSION_KEY,
        secret: SecureRandom.hex(64)
  end
end
# end

SampleApp.initialize!
