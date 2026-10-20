# frozen_string_literal: true

module Phlex
  module Shadcn
    module Doctor
      module Checks
        # The engine's Tailwind bundle (`app/assets/builds/tailwind/phlex-shadcn`) imported by the managed block, and built.
        #
        # @api private
        module EngineBundle
          NAME = "engine bundle"
          BUNDLE = "app/assets/builds/tailwind/phlex-shadcn"
          IMPORT = /^@import\s+["']([^"']+)["']/

          # @param context [Context]
          # @return [Result]
          def self.call(context)
            block = context.managed_block
            return Result.fail(NAME, "no phlex-shadcn block in #{context.css_name}", fix: SourceBlock::INSTALL) unless block

            target = context.path(BUNDLE)
            imported = block.scan(IMPORT).flatten.map { |value| context.resolve_from_css(value).to_s.delete_suffix(".css") }
            return Result.fail(NAME, "the block does not import #{BUNDLE}", fix: SourceBlock::INSTALL) unless imported.include?(target.to_s)
            return Result.pass(NAME, "#{BUNDLE} is imported and built") if target.sub_ext(".css").file?

            Result.warn(NAME, "#{BUNDLE}.css is not built yet", fix: "bin/rails tailwindcss:build")
          end
        end
      end
    end
  end
end
