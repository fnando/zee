# frozen_string_literal: true

module Zee
  class Controller
    module Meta
      # @api private
      class ActionAlias
        def self.aliases
          @aliases ||= {
            "update" => "edit",
            "create" => "new",
            "destroy" => "remove"
          }
        end

        def initialize(action)
          @action = action
        end

        def to_s
          self.class.aliases[@action] || @action
        end
      end
    end
  end
end
