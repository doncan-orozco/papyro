# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "controllers/ui/base_controller", to: "controllers/ui/base_controller.js"
pin "house", to: "house.min.js"
pin "@floating-ui/core", to: "@floating-ui--core.js" # @1.6.0
pin "@floating-ui/dom", to: "@floating-ui--dom.js" # @1.6.3
pin "@floating-ui/utils", to: "@floating-ui--utils.js" # @0.2.11
pin "@floating-ui/utils/dom", to: "@floating-ui--utils--dom.js" # @0.2.11
