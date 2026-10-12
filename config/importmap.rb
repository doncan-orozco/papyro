# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
# phlex-shadcn (temporary bridge until the gem's own engine pins these): the files live in the gem as controllers/shadcn/*,
# the identifiers stay v2--* for now, so the pins keep the controllers/v2 module names.
pin_all_from "gems/phlex-shadcn/app/javascript/controllers/shadcn", under: "controllers/v2", to: "controllers/shadcn"
pin_all_from "gems/phlex-shadcn/app/javascript/shadcn", under: "shadcn"
pin "controllers/ui/base_controller", to: "controllers/ui/base_controller.js"
pin "house", to: "house.min.js"
pin "@floating-ui/core", to: "@floating-ui--core.js" # @1.8.0
pin "@floating-ui/dom", to: "@floating-ui--dom.js" # @1.8.0
pin "@floating-ui/utils", to: "@floating-ui--utils.js" # @0.2.12
pin "@floating-ui/utils/dom", to: "@floating-ui--utils--dom.js" # @0.2.12
