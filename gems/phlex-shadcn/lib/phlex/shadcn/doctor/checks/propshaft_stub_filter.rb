# frozen_string_literal: true

module Phlex
  module Shadcn
    module Doctor
      module Checks
        # With Propshaft and tailwindcss-rails, the gem hides the Tailwind stubs from the served assets unless the app turned that off.
        #
        # @api private
        module PropshaftStubFilter
          NAME = "propshaft stub filter"

          # @param context [Context]
          # @return [Result]
          def self.call(context)
            unless context.gem_version("propshaft") && context.gem_version("tailwindcss-rails")
              return Result.pass(NAME, "not applicable (needs Propshaft and tailwindcss-rails)")
            end
            return Result.pass(NAME, "the Tailwind stubs are hidden from the served assets") if context.hide_tailwind_stubs?

            Result.warn(NAME, "config.phlex_shadcn.hide_tailwind_stubs is false: stylesheet_link_tag :app links stubs that 404",
                        fix: "remove config.phlex_shadcn.hide_tailwind_stubs = false, or exclude app/assets/builds/tailwind yourself")
          end
        end
      end
    end
  end
end
