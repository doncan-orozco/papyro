# frozen_string_literal: true

module Phlex
  module Shadcn
    module Doctor
      module Checks
        # The managed block `rails g phlex:shadcn:install` writes, with an `@source` line that points at the gem's Ruby files (without it
        # Tailwind generates none of the component classes).
        #
        # @api private
        module SourceBlock
          NAME = "source block"
          INSTALL = "bin/rails g phlex:shadcn:install"
          SOURCE = /^@source\s+["']([^"']+)["']/

          # @param context [Context]
          # @return [Result]
          def self.call(context)
            return Result.fail(NAME, "#{context.css_name} not found", fix: "bin/rails tailwindcss:install, then #{INSTALL}") unless context.css_text

            block = context.managed_block
            return Result.fail(NAME, "no phlex-shadcn block in #{context.css_name}", fix: INSTALL) unless block

            sources = block.scan(SOURCE).flatten.map { |value| context.resolve_from_css(value) }
            return Result.fail(NAME, "the block has no @source line", fix: INSTALL) if sources.empty?
            return Result.pass(NAME, "@source points at the gem's lib") if sources.include?(context.gem_root.join("lib"))

            Result.warn(NAME, "@source does not point at #{context.gem_root.join('lib')} (the gem moved?)", fix: INSTALL)
          end
        end
      end
    end
  end
end
