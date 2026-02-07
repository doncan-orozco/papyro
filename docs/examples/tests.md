# Test Examples (Minitest)

All tests use Minitest with fixtures.

## Operation Test

```ruby
# test/concepts/game/operation/move_player_test.rb
require 'test_helper'

class Game::Operation::MovePlayerTest < ActiveSupport::TestCase
  test "should move player up when path is clear" do
    player = players(:hero)
    
    result = Game::Operation::MovePlayer.call(
      params: { direction: "move_up", game_id: player.game_id },
      current_user: player.user
    )
    
    assert result.success?
    assert_equal player.y + 1, result[:player].reload.y
  end
  
  test "should fail when obstacle blocks path" do
    player = players(:hero)
    obstacles(:wall_above_hero)
    
    result = Game::Operation::MovePlayer.call(
      params: { direction: "move_up", game_id: player.game_id },
      current_user: player.user
    )
    
    assert result.failure?
    assert_includes result[:error], "obstacle"
  end
  
  test "should broadcast movement on success" do
    player = players(:hero)
    
    assert_broadcasts_on(GameChannel.broadcasting_for(player.game)) do
      Game::Operation::MovePlayer.call(
        params: { direction: "move_up", game_id: player.game_id },
        current_user: player.user
      )
    end
  end
end
```

## Channel Test

```ruby
# test/channels/game_channel_test.rb
require 'test_helper'

class GameChannelTest < ActionCable::Channel::TestCase
  test "subscribes successfully for authorized player" do
    user = users(:hero_user)
    player = players(:hero)
    game = games(:active_game)
    
    stub_connection(current_user: user)
    
    subscribe game_id: game.id
    
    assert subscription.confirmed?
    assert_has_stream_for game
  end
  
  test "rejects unauthorized player" do
    user = users(:villain_user)
    game = games(:hero_game)
    
    stub_connection(current_user: user)
    
    subscribe game_id: game.id
    
    assert subscription.rejected?
  end
  
  test "handles move action" do
    user = users(:hero_user)
    game = games(:active_game)
    
    stub_connection(current_user: user)
    subscribe game_id: game.id
    
    perform :move, direction: 'move_up'
    
    # Assert broadcast was sent
    assert_broadcasts_on(GameChannel.broadcasting_for(game), 1)
  end
end
```

## Phlex Component Test

```ruby
# test/components/ui/button_test.rb
require "test_helper"

class Components::Ui::ButtonTest < ActionView::TestCase
  test "renders default button" do
    render Components::Ui::Button.new { "Save" }

    assert_includes rendered, "Save"
    assert_includes rendered, "inline-flex"
  end
end
```

## Test Structure

```
test/
  concepts/
    game/
      operation/
        move_player_test.rb
      contract/
        move_player_test.rb
    player/
      operation/
        create_test.rb
  channels/
    game_channel_test.rb
  fixtures/
```

## Rules
- Use fixtures for test data
- Test Operations in isolation
- Test happy path AND failure scenarios
- Test WebSocket interactions
- Use descriptive test names
