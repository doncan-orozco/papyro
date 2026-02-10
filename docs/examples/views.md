# Phlex Views Example

**For complete guidelines, see: [ai_agent/VERIFICATION_CHECKLIST.md](../../ai_agent/VERIFICATION_CHECKLIST.md#views)**

Page-level views rendered by controllers. Views compose components and receive data from controllers. Code examples below.

## Structure

```
app/views/
  games/
    index.rb      # List all games
    show.rb       # Display single game
  players/
    index.rb
    new.rb        # Create form
    edit.rb       # Edit form
```

## Namespace

Views use the `Views::` namespace (different from `Components::`):

```ruby
# app/views/games/index.rb
module Views
  module Games
    class Index < Views::Base
      def initialize(games:)
        @games = games
      end

      def view_template
        div(class: "container mx-auto py-8") do
          h1(class: "text-3xl font-bold mb-6") { "Games" }
          
          div(class: "grid grid-cols-1 md:grid-cols-3 gap-4") do
            @games.each do |game|
              render Components::Game::PlayerCard.new(game: game)
            end
          end
          
          link_to("New Game", new_game_path, class: "btn btn-primary")
        end
      end
    end
  end
end
```

## Key Points

- One view per controller action (index, show, new, edit, create)
- Receives data from controller via constructor arguments
- Composes `Components::*` for UI elements
- Uses Phlex syntax (`div`, `h1`, `link_to`, etc.)
- No instance variables (pass all data via arguments)
- Views must inherit `Views::Base`

## Controller Integration

```ruby
# app/controllers/games_controller.rb
class GamesController < ApplicationController
  def index
    games = Game.all
    render Views::Games::Index.new(games: games)
  end

  def show
    game = Game.find(params[:id])
    render Views::Games::Show.new(game: game)
  end

  def new
    form = Games::Contract::Create.new
    render Views::Games::New.new(form: form)
  end
end
```

## Differences from Components

| Aspect | Views | Components |
|--------|-------|-----------|
| **Location** | `app/views/` | `app/components/` |
| **Namespace** | `Views::` | `Components::` |
| **Purpose** | Page-level templates | Reusable UI elements |
| **Rendered By** | Controllers | Views and other components |
| **Data** | From controller (large datasets) | From parent component (focused params) |
| **Composition** | Top-level layout, includes components | Smaller UI pieces |

## Example: New Player Form

```ruby
# app/views/players/new.rb
module Views
  module Players
    class New < Views::Base
      def initialize(form:)
        @form = form
      end

      def view_template
        div(class: "max-w-2xl mx-auto") do
          h1(class: "text-2xl font-bold mb-4") { "Create Player" }
          
          form_with(model: Player.new, local: true) do |f|
            render Components::Ui::FormErrors.new(form: @form) if @form.errors.any?
            
            div(class: "mb-4") do
              f.label :name
              f.text_field :name, class: "input"
            end
            
            div(class: "mb-4") do
              f.label :class_name
              f.select :class_name, ["Warrior", "Mage", "Rogue"], {}, class: "select"
            end
            
            f.submit "Create", class: "btn btn-primary"
          end
        end
      end
    end
  end
end
```
