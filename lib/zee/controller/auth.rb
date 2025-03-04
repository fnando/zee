# frozen_string_literal: true

module Zee
  class Controller
    module Auth
      # Raised when a method is not implemented.
      NotImplementedError = Class.new(StandardError)

      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        # TODO: write docs
        def auth_scope(*scopes, when_logged_in:, when_logged_out:)
          scopes.each do |scope|
            setup_auth_instance_methods(
              scope,
              when_logged_in:,
              when_logged_out:
            )
          end
        end
        alias auth_scopes auth_scope

        def setup_auth_instance_methods(
          scope,
          when_logged_in:,
          when_logged_out:
        )
          define_method :"create_#{scope}_session" do |id|
            session["#{scope}_id"] = id
          end

          define_method :"current_#{scope}" do
            # :nocov:
            raise NotImplementedError, "You must implement #current_#{scope}"
            # :nocov:
          end

          define_method :"#{scope}_logged_in?" do
            !send(:"current_#{scope}").nil?
          end

          define_method :"require_logged_#{scope}" do
            return if send(:"#{scope}_logged_in?")

            instance_eval(&when_logged_out)
          end

          define_method :"redirect_logged_#{scope}" do
            return unless send(:"#{scope}_logged_in?")

            instance_eval(&when_logged_in)
          end

          private :"current_#{scope}", :"#{scope}_logged_in?"
          expose :"current_#{scope}", :"#{scope}_logged_in?"
        end
      end
    end
  end
end
