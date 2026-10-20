# frozen_string_literal: true

module Phlex
  module Shadcn
    module Doctor
      module Checks
        # theme.css and presets/ exist in the theme directory.
        #
        # @api private
        module ThemeFiles
          NAME = "theme files"

          # @param context [Context]
          # @return [Result]
          def self.call(context)
            dir = context.theme_dir
            return Result.fail(NAME, "no theme directory configured", fix: "set config.phlex_shadcn.theme_dir in config/application.rb") unless dir
            return Result.fail(NAME, "theme.css not found in #{dir}", fix: SourceBlock::INSTALL) unless dir.join("theme.css").file?
            return Result.warn(NAME, "#{dir}/presets is missing", fix: "#{SourceBlock::INSTALL} (copies the presets that are not there)") unless dir.join("presets").directory?

            Result.pass(NAME, "theme.css and presets/ in #{dir}")
          end
        end
      end
    end
  end
end
