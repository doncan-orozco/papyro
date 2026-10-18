# frozen_string_literal: true

# Alias shim: the class lives in gems/phlex-shadcn/dev/parity (shared with the dummy app); removed with the host harness.
require Rails.root.join("gems/phlex-shadcn/dev/parity/lib/shadcn_parity").to_s
Components::Parity::Scenario = ShadcnParity::Scenario
