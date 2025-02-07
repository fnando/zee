# frozen_string_literal: true

SampleApp = Zee::App.new do
  self.root = Pathname(__dir__)

  routes do
    root to: "pages#home"
    get "missing-template", to: "pages#missing_template"
  end
end

SampleApp.initialize!
