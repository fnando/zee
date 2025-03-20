# frozen_string_literal: true

module Zee
  class Controller
    # Flash messages are used to display messages to the user. They are
    # available to the next action and will be discarded after that.
    #
    # ```ruby
    # class MyController < Zee::Controller
    #   def index
    #     flash[:notice] = "Hello, World!"
    #   end
    #
    #   def show
    #     flash.now[:alert] = "Goodbye, World!"
    #   end
    # end
    # ```
    #
    # In the above example, the `index` action will display the notice message
    # on the next request, while the `show` action will display the alert
    # message on the current request.
    #
    # Alternatively, you can use the `notice`, `alert`, `info`, and `error`
    # method as shortcuts to set the flash message.
    #
    # ```ruby
    # class MyController < Zee::Controller
    #   def index
    #     flash.notice = "Hello, World!"
    #   end
    #
    #   def show
    #     flash.now.alert = "Goodbye, World!"
    #   end
    # end
    # ```
    #
    # Another common pattern is to set flash messages right before redirecting
    # users. You can also do it in a single line.
    #
    # ```ruby
    # class MyController < Zee::Controller
    #   def create
    #     redirect_to "/users", notice: "User created successfully."
    #   end
    # end
    # ```
    #
    # @see Controller::Flash::FlashHash
    # @see Controller::Redirect#redirect_to
    # @see Middleware::Flash
    module Flash
      def self.included(target)
        target.helper_method(:flash)
      end

      # Define the flash object.
      private def flash
        @flash ||= FlashHash.new(session)
      end

      class FlashHash
        def initialize(store)
          @store = store
          @store[:flash] ||= {messages: {}, discard: []}
          @discard = @store[:flash][:discard]
          @messages = @store[:flash][:messages]
        end

        # Iterates over each flash message.
        def each(&)
          @messages.each(&)
        end

        # Checks if the flash is empty.
        def empty?
          @messages.empty?
        end

        # Checks if the flash has any messages.
        def any?
          @messages.any?
        end

        # Sets a flash that will not be available to the next action, only to
        # the current.
        #
        # Entries set via `flash.now` are accessed the same way as standard
        # entries.
        #
        # @example
        #   flash.now.alert = "Just now!"
        #   flash.alert
        #   #=> "Just now!"
        def now
          @now ||= FlashNow.new(self)
        end

        # Discard the flash message.
        # @param key [Symbol]
        def discard(key)
          @discard << key if @messages.key?(key)
        end

        # Keep the flash message.
        # @param key [Symbol, nil] The key of the message to keep. If `nil`, all
        #                          messages will be kept.
        def keep(key = nil)
          if key
            @discard.delete(key)
          else
            @discard.clear
          end
        end

        # Discard the flash message.
        # @param key [Symbol]
        def delete(key)
          @messages.delete(key)
          @discard.delete(key)
        end

        # Clear all flash messages.
        def clear
          @messages.clear
          @discard.clear
        end

        # Get the flash message.
        # @param key [Symbol]
        # @return [String, nil]
        def [](key)
          @messages[key]
        end

        # Set the flash message.
        # @param key [Symbol]
        # @param message [String]
        # @return [String]
        def []=(key, message)
          @messages[key] = message
        end

        # Get the notice message.
        # @return [String, nil]
        def notice
          self[:notice]
        end

        # Set the notice message.
        # @param message [String]
        # @return [String]
        def notice=(message)
          self[:notice] = message
        end

        # Get the alert message.
        # @return [String, nil]
        def alert
          self[:alert]
        end

        # Set the alert message.
        # @param message [String]
        # @return [String]
        def alert=(message)
          self[:alert] = message
        end

        # Get the info message.
        # @return [String, nil]
        def info
          self[:info]
        end

        # Set the info message.
        # @param message [String]
        def info=(message)
          self[:info] = message
        end

        # Get the error message.
        # @return [String, nil]
        def error
          self[:error]
        end

        # Set the error message.
        # @param message [String]
        def error=(message)
          self[:error] = message
        end
      end

      class FlashNow
        def initialize(flash)
          @flash = flash
        end

        def []=(key, value)
          @flash[key] = value
          @flash.discard(key)
        end

        # Set the notice message.
        # @param message [String]
        # @return [String]
        def notice=(message)
          self[:notice] = message
        end

        # Set the alert message.
        # @param message [String]
        # @return [String]
        def alert=(message)
          self[:alert] = message
        end

        # Set the info message.
        # @param message [String]
        def info=(message)
          self[:info] = message
        end

        # Set the error message.
        # @param message [String]
        def error=(message)
          self[:error] = message
        end
      end
    end
  end
end
