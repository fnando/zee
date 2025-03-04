# frozen_string_literal: true

module Zee
  class Controller
    module Auth
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        # TODO: write docs
        def auth_scope(*scopes)
        end
        alias auth_scopes auth_scope
      end
    end
  end
end
