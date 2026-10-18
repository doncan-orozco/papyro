# Active Storage (>= 8.1.3.1) calls Vips.block_untrusted(true), which disables libvips's unfuzzed
# loaders. The OG image generator rasterizes an SVG that our own template renders (never user
# input), so re-enable only the SVG loader and leave every other untrusted loader blocked.
Vips.block("VipsForeignLoadSvg", false) if defined?(Vips) && Vips.respond_to?(:block)
