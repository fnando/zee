SampleApp = Zee::App.new do
  self.root = Pathname(__dir__)

  routes do
    root to: "pages#home"
    get "missing-template", to: "pages#missing_template"
    get "hello", to: "pages#hello"
  end
end

SampleApp.initialize!
