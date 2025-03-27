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
        # The generator must a  Thor::Group subclass.
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
