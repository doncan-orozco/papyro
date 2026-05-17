---
name: realtime
description: Real-time communication patterns with Action Cable and dry-rb operations. Use when implementing WebSocket channels, broadcasting updates, or handling real-time features. Covers channel organization, authorization, messaging patterns, and operation broadcasting.
---

# Realtime (Action Cable + dry-rb)

## Dependencies
- actioncable
- dry-monads

## Channels Organization (Pattern)
- `app/channels/` hosts channel classes
- One channel per domain concept (game/room)
- Authorization happens in `subscribed`
- Use `stream_for` with domain instances
- Keep channels thin and delegate logic to operations

## Messages (Pattern)
- JSON payloads with `type` and small deltas
- Include timestamps in broadcasts

## Operations Broadcasting (Pattern)
- Broadcast inside Operations after successful state changes
- Example: `Game::BroadcastChannel.broadcast_to(game, { type: 'player_moved', ... })`

## Reference Map

- **[references/channels.md](references/channels.md)**
	Use for concrete channel structure, subscription flow, client action handling, and broadcasting examples.

See [Channels](/.github/copilot-instructions.md#channels-action-cable) for requirements.

