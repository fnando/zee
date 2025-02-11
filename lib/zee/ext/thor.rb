# frozen_string_literal: true

Thor::Command.instance_eval do
  mod = Module.new do
    def run(instance, *args)
      namespace, _ = *name.split(":").map(&:to_sym)

      # Run before run hooks
      Zee::CLI.before_run_hooks[namespace]&.each(&:call)

      super
    end
  end

  prepend mod
end
