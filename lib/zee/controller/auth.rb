# frozen_string_literal: true

module Zee
  class Controller
    # The authentication module for controllers that require user
    # authentication. It supports multiple scopes, like `user` and `admin`.
    #
    # > [!NOTE]
    # > This is an opt-in module. To enable it, you must include this module to
    # > your controller, like `include Zee::Controller::Auth`.
    #
    # The `auth_scope` method is used to define the scopes and the methods that
    # will be available in the controller. With these methods, you can access
    # the current user, check if the user is logged in, require the user to
    # be logged in, or redirect the user to the login page.
    #
    # To use the authentication module, you must include it in your controller
    # and call the `auth_scope` method. The `auth_scope` method receives the
    # scopes that you want to define and two procs: one that will be called
    # when the user is logged in and another when the user is logged out.
    #
    # ```ruby
    # module Controllers
    #   class Base < Zee::Controller
    #     # Include the authentication module.
    #     include Zee::Controller::Auth
    #
    #     # Define the user scope.
    #     auth_scope :user,
    #                when_logged_in: proc { redirect_to dashboard_path },
    #                when_logged_out: proc { redirect_to login_path }
    #   end
    # end
    # ```
    #
    # The method `auth_scope` will define the following methods in the
    # controller:
    #
    # - `create_user_session`: Creates a new session for the user.
    # - `current_user`: Returns the current user. This is the only method that
    #   you must implement in the controller.
    # - `user_logged_in?`: Checks if the user is logged in.
    # - `authorized_user?`: Checks if the user is authorized. By default, it
    #   returns `true` if user is logged in, so you can customize it if you
    #   want.
    # - `require_logged_user`: Requires the user to be logged in. Must be used
    #   as a before action.
    # - `redirect_logged_user`: Redirects the user to the dashboard if logged
    #   in. Must be used as a before action.
    #
    # The `current_user` method must be implemented in the controller. This
    # method should return the current user. If the user is not logged in, it
    # should return `nil`. The value that'll be set to `session[:user_id]` will
    # be provided by you when you create the session.
    #
    # ```ruby
    # module Controllers
    #   class Base < Zee::Controller
    #     # Include the authentication module.
    #     include Zee::Controller::Auth
    #
    #     # Define the user scope.
    #     auth_scope :user,
    #                when_logged_in: proc { redirect_to dashboard_path },
    #                when_logged_out: proc { redirect_to return_to(login_path) }
    #
    #     private def current_user
    #       @current_user ||= User[session[:user_id]] if session[:user_id]
    #     end
    #   end
    # end
    # ```
    # Now that the auth scope is defined, you can guard you controllers with
    # before actions.
    #
    # > [!NOTE]
    # > When creating a new session with `current_user_session`, this method
    # > will automatically call `reset_session` before setting the new id.
    # > The only session value that will be persisted from the old session to
    # > the new one is `:return_to`.
    module Auth
      # Raised when a method is not implemented.
      NotImplementedError = Class.new(StandardError)

      def self.included(base)
        base.extend(ClassMethods)
        base.include(InstanceMethods)
      end

      module InstanceMethods
        # Whenever `before_action :required_logged_user` is triggered, the
        # current url is persisted if you just tried a `GET` request.
        #
        # The `return_to` helper will give you the requested url (before the
        # user logged in) or the default url.
        private def return_to(url)
          session.delete(:return_to) || url
        end
      end

      module ClassMethods
        # Define the authentication scopes for the controller.
        # This method will define the methods that will be available in the
        # controller for each scope.
        # @param scopes [Array<Symbol>] The scopes to define.
        # @param when_logged_in [Proc] The block to execute when the user is
        #                              logged in but tries to access an action
        #                              that's guarded by
        #                              `before_action :redirect_logged_user`.
        # @param when_logged_out [Proc] The block to execute when the user is
        #                               logged out but tries to access an action
        #                               that's guarded by
        #                               `before_action :require_logged_user`.
        # @param when_unauthorized [Proc, nil] The block to execute when the
        #                                      user is not authorized to access
        #                                      the action. Defaults to the same
        #                                      behavior defined in the
        #                                      `when_logged_out` block.
        # @example Define the user scope.
        # ```ruby
        # module Controllers
        #   class Base < Zee::Controller
        #     # Include the authentication module.
        #     include Zee::Controller::Auth
        #
        #     # Define the user scope.
        #     auth_scope :user,
        #           when_logged_in: proc { redirect_to dashboard_path },
        #           when_logged_out: proc { redirect_to login_path }
        #   end
        # end
        # ```
        def auth_scope(
          *scopes,
          when_logged_in:,
          when_logged_out:,
          when_unauthorized: nil
        )
          when_unauthorized ||= proc do
            render text: "Unauthorized", status: 401
          end

          scopes.each do |scope|
            setup_auth_instance_methods(
              scope,
              when_logged_in:,
              when_logged_out:,
              when_unauthorized:
            )
          end
        end
        alias auth_scopes auth_scope

        # @api private
        private def setup_auth_instance_methods(
          scope,
          when_logged_in:,
          when_logged_out:,
          when_unauthorized:
        )
          create_session = :"create_#{scope}_session"
          authorized = :"authorized_#{scope}?"
          logged_in = :"#{scope}_logged_in?"
          current = :"current_#{scope}"
          require_logged_in = :"require_logged_#{scope}"
          redirect_logged_in = :"redirect_logged_#{scope}"
          session_key = :"#{scope}_id"

          define_method create_session do |id|
            url = session.delete(:return_to)
            reset_session
            session[session_key] = id
            session[:return_to] = url if url
          end

          define_method current do
            # :nocov:
            raise NotImplementedError, "You must implement #current_#{scope}"
            # :nocov:
          end

          define_method logged_in do
            !send(current).nil?
          end

          define_method require_logged_in do
            block = when_logged_out

            if send(logged_in)
              return if send(authorized)

              block = when_unauthorized
            end

            session[:return_to] = request.fullpath if request.get?

            instance_eval(&block)
          end

          define_method redirect_logged_in do
            return unless send(logged_in)

            instance_eval(&when_logged_in)
          end

          define_method authorized do
            send(logged_in)
          end

          # Mark methods that will be exposed to the views as private.
          # Only the necessary methods will be exposed.
          private current, logged_in
          expose current, logged_in
        end
      end
    end
  end
end
