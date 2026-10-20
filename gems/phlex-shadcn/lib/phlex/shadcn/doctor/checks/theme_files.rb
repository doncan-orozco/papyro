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
            return Result.failure(NAME, "no theme directory configured", fix: Context::THEME_DIR_FIX) unless dir
            return Result.failure(NAME, "theme.css not found in #{dir}", fix: Context::INSTALL) unless dir.join("theme.css").file?
            unless dir.join("presets").directory?
              return Result.warning(NAME, "#{dir}/presets is missing",
                                    fix: "#{Context::INSTALL} (copies the presets that are not there)")
            end

            Result.passed(NAME, "theme.css and presets/ in #{dir}")
          end
        end
      end
    end
  end
end
