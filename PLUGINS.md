# Writing plugins

## Writing CLI plugins

To create a new CLI plugin, you must define a file at `lib/zee/*_cli_plugin.rb`.
This file will then add any additional command you want to the CLI.

The following example adds a new command to the CLI that prints "hello".

```ruby
# lib/zee/hello_cli_plugin.rb
module Zee
  module CLI
    class Root < Command
      desc "hello", "Prints hello"
      def hello
        shell.say "Hello there!", :blue
      end
    end
  end
end
```

To add a new `generate` subcommand, you can do something similar, but targeting
the `Zee::CLI::Generate` command:

```ruby
# lib/zee/hello_cli_plugin.rb
module Zee
  module CLI
    class Phlex < Command
      desc "phlex", "Generate phlex components"
      def phlex
        # The generator must a Thor::Group subclass.
        # https://nandovieira.com/creating-generators-and-executables-with-thor
        generator = PhlexGenerator.new
        generator.destination_root = File.expand_path(path)
        generator.options = options
        generator.invoke_all
      end
    end
  end
end
```

## Model Validations

To add new validations to the model, you must define a new class module that
defines the `self.validate(model, attribute, options)` method. Then you must
extend `Zee::Model` with this module.

Let's create a validator for emails. It's a simple regex that checks if the
email is valid.

```ruby
module Zee
  class Model
    module Validations
      module Email
        DEFAULT_MESSAGE = "is not a valid email"
        EMAIL_RE = /\A[\w-.]+@[a-z0-9-]+(\.[a-z0-9-])+\z/i

        def self.validate(model, attribute, options)
          value = model[attribute].to_s

          return if value.match?(EMAIL_RE)

          message = model.errors.build_error_message(:email, attribute) ||
                    options[:message] ||
                    DEFAULT_MESSAGE

          model.errors.add(attribute, :email, message:)
        end

        def validates_email(*names, **options)
          validations << Validator.new(Email, names, options)
        end
      end
    end
  end
end
```
