require 'execjs'

module Tilt
  class ES6ModuleTranspilerTemplate < Tilt::Template
    self.default_mime_type = 'application/javascript'

    Node = ::ExecJS::ExternalRuntime.new(
      name: 'Node.js (V8)',
      command: ['nodejs', 'node'],
      runner_path: File.expand_path('../../support/es6_node_runner.js', __FILE__),
      encoding: 'UTF-8'
    )

    def prepare
      # intentionally left empty
      # Tilt requires this method to be defined
    end

    def evaluate(scope, locals, &block)
      @output ||= Node.exec(generate_source(scope))
    end

    private

    def transpiler_path
      File.expand_path('../../support/es6-module-transpiler.js', __FILE__)
    end

    def generate_source(scope)
      source = <<-SOURCE
        var Compiler, compiler, output;
        Compiler = require("#{transpiler_path}").Compiler;
        compiler = new Compiler(#{::JSON.generate(data, quirks_mode: true)}, '#{module_name(scope.root_path, scope.logical_path)}');
        return output = compiler.#{compiler_method}();
      SOURCE
    end

    def module_name(root_path, logical_path)
      if prefix = ES6ModuleTranspiler.lookup_prefix(File.join(root_path, logical_path))
        path = File.join(prefix, logical_path)
      else
        logical_path
      end
    end

    def compiler_method
      type = {
        amd: 'AMD',
        cjs: 'CJS',
        globals: 'Globals'
      }[ES6ModuleTranspiler.compile_to.to_sym]

      "to#{type}"
    end
  end
end
