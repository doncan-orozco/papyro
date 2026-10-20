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
          REGISTRATION = /eagerLoadControllersFrom\(\s*["']controllers["']/
          FILES = %w[app/javascript/controllers/index.js app/javascript/application.js].freeze

          # @param context [Context]
          # @return [Result]
          def self.call(context)
            unless context.gem_version("stimulus-rails")
              return Result.fail(NAME, "stimulus-rails is not in the bundle", fix: "bundle add stimulus-rails && bin/rails stimulus:install")
            end

            registered = FILES.any? { |file| context.path(file).file? && context.path(file).read.match?(REGISTRATION) }
            return Result.pass(NAME, %(eagerLoadControllersFrom("controllers") registers the gem's shadcn--* controllers)) if registered

            Result.fail(NAME, %(no eagerLoadControllersFrom("controllers", application) in #{FILES.join(' or ')}),
                        fix: %(add eagerLoadControllersFrom("controllers", application) to app/javascript/controllers/index.js))
          end
        end
      end
    end
  end
end
