# Stimulus Controller Examples

**For complete guidelines, see: [VERIFICATION_CHECKLIST.md](../../../VERIFICATION_CHECKLIST.md#stimulus)**

Stimulus controllers handle frontend behavior and WebSocket integration. Code examples and naming conventions below.

## File Structure

```
app/javascript/
  application.js
  controllers/
    application.js         # Base controller
    index.js              # Controller registration
    game/
      connection_controller.js
      player_controller.js
      move_controller.js
    ui/
      modal_controller.js
      dropdown_controller.js
```

## Registration (index.js)

```javascript
// app/javascript/controllers/index.js
import { application } from "./application"

// Eager load all controllers
import GameConnectionController from "./game/connection_controller"
import GamePlayerController from "./game/player_controller"
import UiModalController from "./ui/modal_controller"

application.register("game--connection", GameConnectionController)
application.register("game--player", GamePlayerController)
application.register("ui--modal", UiModalController)
```

## WebSocket Connection Controller

```javascript
// app/javascript/controllers/game/connection_controller.js
import { Controller } from '@hotwired/stimulus'
import { createConsumer } from '@rails/actioncable'

export default class extends Controller {
  static values = {
    gameId: Number
  }
  
  static targets = ['status']
  
  connect() {
    this.channel = createConsumer().subscriptions.create(
      { channel: 'Game::BroadcastChannel', game_id: this.gameIdValue },
      {
        connected: () => this.handleConnected(),
        disconnected: () => this.handleDisconnected(),
        received: (data) => this.handleReceived(data)
      }
    )
  }
  
  disconnect() {
    if (this.channel) {
      this.channel.unsubscribe()
    }
  }
  
  handleConnected() {
    console.log('Connected to game channel')
    this.updateStatus('connected')
  }
  
  handleDisconnected() {
    console.log('Disconnected from game channel')
    this.updateStatus('disconnected')
  }
  
  handleReceived(data) {
    const { type, ...payload } = data
    
    // Dispatch custom events for other controllers
    this.dispatch(type, { detail: payload })
    
    switch(type) {
      case 'game_state':
        this.handleGameState(payload)
        break
      case 'player_moved':
        this.handlePlayerMoved(payload)
        break
      case 'error':
        this.handleError(payload)
        break
    }
  }
  
  handlePlayerMoved({ player_id, x, y, direction }) {
    this.dispatch('player-moved', { 
      detail: { playerId: player_id, x, y, direction }
    })
  }
  
  updateStatus(status) {
    if (this.hasStatusTarget) {
      this.statusTarget.textContent = status
      this.statusTarget.dataset.status = status
    }
  }
  
  // Called by other controllers to send actions
  send(action, data = {}) {
    if (this.channel) {
      this.channel.perform(action, data)
    }
  }
}
```

## Hotkeys Controller

```javascript
// app/javascript/controllers/hotkeys_controller.js
import { Controller } from '@hotwired/stimulus'
import { useHotkeys } from 'stimulus-use/hotkeys'

export default class extends Controller {
  static outlets = ['game--connection']
  
  connect() {
    useHotkeys(this, {
      hotkeys: {
        'w': {
          handler: () => this.move('move_up'),
          options: { keydown: true, keyup: false, single: true, capture: true }
        },
        's': {
          handler: () => this.move('move_down'),
          options: { keydown: true, keyup: false, single: true, capture: true }
        },
        'a': {
          handler: () => this.move('move_left'),
          options: { keydown: true, keyup: false, single: true, capture: true }
        },
        'd': {
          handler: () => this.move('move_right'),
          options: { keydown: true, keyup: false, single: true, capture: true }
        }
      }
    })
  }
  
  move(direction) {
    if (this.hasGameConnectionOutlet) {
      this.gameConnectionOutlet.send('move', { direction })
    }
  }
}
```

## Player Controller

```javascript
// app/javascript/controllers/game/player_controller.js
import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static values = {
    playerId: Number,
    x: Number,
    y: Number
  }
  
  connect() {
    this.element.addEventListener('game--connection:player-moved', (e) => {
      this.handlePlayerMoved(e)
    })
  }
  
  handlePlayerMoved(event) {
    const { playerId, x, y, direction } = event.detail
    
    if (playerId === this.playerIdValue) {
      this.updatePosition(x, y, direction)
    }
  }
  
  updatePosition(x, y, direction) {
    this.xValue = x
    this.yValue = y
    
    // Animate movement
    const pixelSize = 32 // pixels per game unit
    this.element.style.transform = `translate(${x * pixelSize}px, ${y * pixelSize}px)`
    this.element.classList.add(`moving-${direction}`)
    
    setTimeout(() => {
      this.element.classList.remove(`moving-${direction}`)
    }, 200)
  }
}
```

## Naming Convention

```
app/javascript/controllers/
├── game/
│   ├── connection_controller.js    # data-controller="game--connection"
│   ├── player_controller.js        # data-controller="game--player"
│   └── inventory_controller.js     # data-controller="game--inventory"
├── ui/
│   ├── modal_controller.js         # data-controller="ui--modal"
│   └── dropdown_controller.js      # data-controller="ui--dropdown"
└── hotkeys_controller.js           # data-controller="hotkeys"
```

See [VERIFICATION_CHECKLIST.md](../../../VERIFICATION_CHECKLIST.md#stimulus) for complete Stimulus guidelines.
