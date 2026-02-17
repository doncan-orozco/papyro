# frozen_string_literal: true

# @label Card  
# @display bg_color "#f8f9fa"
class CardPreview < Lookbook::Preview
  # Basic card with all sections
  # @label Default
  def default
    "<div class='rounded-lg border border-border bg-card text-card-foreground shadow-sm max-w-md'><div class='flex flex-col space-y-1.5 p-6'><h3 class='font-semibold leading-none tracking-tight'>Card Title</h3><p class='text-sm text-muted-foreground'>Card description goes here</p></div><div class='p-6 pt-0'><p class='text-sm'>This is the main content area of the card.</p></div><div class='flex items-center p-6 pt-0'><button class='inline-flex items-center justify-center whitespace-nowrap shrink-0 rounded-lg border border-border bg-background text-foreground hover:bg-muted text-sm font-medium h-8 gap-1.5 px-3'>Cancel</button><button class='inline-flex items-center justify-center whitespace-nowrap shrink-0 rounded-lg border border-transparent bg-primary text-primary-foreground hover:bg-primary/90 text-sm font-medium h-8 gap-1.5 px-2.5 ml-2'>Submit</button></div></div>".html_safe
  end

  # Card without footer
  # @label Simple
  def simple
    "<div class='rounded-lg border border-border bg-card text-card-foreground shadow-sm max-w-md'><div class='flex flex-col space-y-1.5 p-6'><h3 class='font-semibold leading-none tracking-tight'>Simple Card</h3><p class='text-sm text-muted-foreground'>A card without a footer</p></div><div class='p-6 pt-0'><p class='text-sm'>This card only has a header and content.</p></div></div>".html_safe
  end

  # Card with just content
  # @label Content Only
  def content_only
    "<div class='rounded-lg border border-border bg-card text-card-foreground shadow-sm max-w-md'><div class='p-6'><p class='text-sm'>This is a card with just content.</p></div></div>".html_safe
  end
end
