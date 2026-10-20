# frozen_string_literal: true

require "json"

module Phlex
  module Shadcn
    # Diagnoses a host app's phlex-shadcn setup (`bin/rails phlex_shadcn:doctor`): one pass / warn / fail line, with a one-line fix,
    # for each prerequisite. Every check is one file under `doctor/checks/` (a class with `.call(context)` returning a {Result}),
    # discovered by file name, so a new check is a new file and no shared file changes. The doctor reads files and gem versions only
    # and never references Rails, so it loads without it; the rake task builds the {Context} from the running app.
    #
    # @api private
    module Doctor
      # Directory the checks are discovered in.
      CHECKS_DIR = File.join(__dir__, "doctor/checks").freeze

      # Runs every check against the context.
      #
      # @param context [Context]
      # @return [Report]
      def self.run(context)
        Report.new(check_classes.map { |check| check.call(context) })
      end

      # The check classes, in file name order (Dir sorts): `doctor/checks/foo_bar.rb` defines `Doctor::Checks::FooBar`.
      #
      # @return [Array<Class>]
      def self.check_classes
        Dir[File.join(CHECKS_DIR, "*.rb")].sort.map do |path|
          Checks.const_get(File.basename(path, ".rb").split("_").map(&:capitalize).join)
        end
      end
    end
  end
end
