# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "controllers/ui/base_controller", to: "controllers/ui/base_controller.js"
pin "house", to: "house.min.js"
pin "@floating-ui/core", to: "https://cdn.jsdelivr.net/npm/@floating-ui/core@1.6.0/+esm"
pin "@floating-ui/dom", to: "https://cdn.jsdelivr.net/npm/@floating-ui/dom@1.6.3/+esm"
