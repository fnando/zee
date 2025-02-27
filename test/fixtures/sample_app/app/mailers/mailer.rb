# frozen_string_literal: true

module Mailers
  class Mailer < Zee::Mailer
    def login(email)
      mail to: email, from: "from@example.com", subject: "Login"
    end
  end
end
