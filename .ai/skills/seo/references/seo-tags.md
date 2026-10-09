# SEO Tag Implementation

## Application Layout Partial
Place this in `<head>` to ensure bots correctly index all language versions.

```erb
<%# 1. Canonical Tag %>
<link rel="canonical" href="<%= request.base_url + request.path %>" />

<%# 2. Hreflang Matrix %>
<% I18n.available_locales.each do |loc| %>
  <link rel="alternate" 
        hreflang="<%= loc %>" 
        href="<%= url_for(locale: loc, only_path: false) %>" />
<% end %>

<%# 3. X-Default (pointing to primary language) %>
<link rel="alternate" 
      hreflang="x-default" 
      href="<%= url_for(locale: I18n.default_locale, only_path: false) %>" />
```