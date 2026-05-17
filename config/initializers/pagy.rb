# frozen_string_literal: true

require "pagy"

# Pagy v43 freezes default settings; configure values at call sites
# (e.g. pagy(relation, page: parse_page, limit: 10)).
