# frozen_string_literal: true

module Zee
  class Model
    extend Zee::Naming

    include Attributes
    include Validations
  end
end
