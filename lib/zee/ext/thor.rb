# frozen_string_literal: true

Thor::Command.instance_eval do
  mod = Module.new do
    def run(instance, *)
      klass = instance.class
      klass.before_run if klass.respond_to?(:before_run)

      super
    end
  end

  prepend mod
end
