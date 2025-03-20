# frozen_string_literal: true

module Zee
  class Controller
    module HelperMethods
      def self.included(controller)
        controller.extend(ClassMethods)
      end

      module ClassMethods
        def inherited(child)
          super
          child.helper_method(*helper_method)
        end

        # Expose helper methods to templates.
        # With this method, you can expose helper methods to all actions.
        #
        # Notice that methods must be private.
        #
        # @example Expose a helper method to all actions.
        #   class ApplicationController < Zee::Controller
        #     helper_methods :current_user, :user_logged_in?
        #
        #     private def current_user
        #       @current_user ||=
        #         Models::User.find(session[:user_id]) if session[:user_id]
        #     end
        #
        #     private def user_logged_in?
        #       current_user != nil
        #     end
        #   end
        def helper_method(*names)
          @helper_method ||= Set.new
          @helper_method += names
          @helper_method
        end
        alias helper_methods helper_method
      end
    end
  end
end
