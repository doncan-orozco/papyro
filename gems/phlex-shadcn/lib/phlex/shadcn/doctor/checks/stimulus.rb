# frozen_string_literal: true

module Phlex
  module Shadcn
    module Doctor
      module Checks
        # The host registers its Stimulus controllers from the `controllers` importmap namespace, where the gem's `shadcn--*` controllers live.
        #
        # @api private
        module Stimulus
          NAME = "stimulus controllers"
          REGISTRATION = /(?:eager|lazy)LoadControllersFrom\(\s*["']controllers["']/
          COMMENT = %r{/\*.*?\*/|//[^\n]*}m
          FILES = %w[app/javascript/controllers/index.js app/javascript/application.js].freeze

          # @param context [Context]
          # @return [Result]
          def self.call(context)
            unless context.gem_version("stimulus-rails")
              return Result.failure(NAME, "stimulus-rails is not in the bundle", fix: "bundle add stimulus-rails && bin/rails stimulus:install")
            end

            registered = FILES.find { |file| registers?(context.path(file)) }
            return Result.passed(NAME, "#{registered} registers the controllers namespace, where the gem's shadcn--* controllers are") if registered

            Result.failure(NAME, %(no eagerLoadControllersFrom("controllers", application) (or lazyLoadControllersFrom) in #{FILES.join(' or ')}),
                           fix: %(add eagerLoadControllersFrom("controllers", application) to app/javascript/controllers/index.js))
          end

          # @param file [Pathname]
          # @return [Boolean] whether the file calls eager/lazyLoadControllersFrom("controllers", ...) outside a comment
          def self.registers?(file)
            return false unless file.file?

            file.read(encoding: "UTF-8").gsub(COMMENT, "").match?(REGISTRATION)
          end
        end
      end
    end
  end
end
