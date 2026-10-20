# frozen_string_literal: true

module Phlex
  module Shadcn
    module Doctor
      module Checks
        # The managed block imports the app's theme file (the one in the configured theme directory).
        #
        # @api private
        module ThemeImport
          NAME = "theme import"

          # @param context [Context]
          # @return [Result]
          def self.call(context)
            block = context.managed_block
            return Result.fail(NAME, "no phlex-shadcn block in #{context.css_name}", fix: SourceBlock::INSTALL) unless block
            unless context.theme_dir
              return Result.fail(NAME, "no theme directory configured", fix: "set config.phlex_shadcn.theme_dir in config/application.rb")
            end

            imported = block.scan(EngineBundle::IMPORT).flatten.map { |value| context.resolve_from_css(value) }
            return Result.pass(NAME, "the block imports #{context.theme_dir.join('theme.css')}") if imported.include?(context.theme_dir.join("theme.css"))

            Result.fail(NAME, "the block does not import #{context.theme_dir.join('theme.css')}", fix: SourceBlock::INSTALL)
          end
        end
      end
    end
  end
end
