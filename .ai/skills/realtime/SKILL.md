---
name: realtime
description: "Action Cable channels and broadcasting with dry-rb operations. Use when creating or editing files in `app/channels/`, broadcasting from operations, or authorizing WebSocket subscriptions."
---

# Realtime (Action Cable + dry-rb)

## Quick Rules

Cite as `realtime R<n>`. Detail and examples follow below / in references/.

R1. **Authorize in subscribed.** Channel authorization happens in `subscribed`, and unauthorized subscriptions are rejected. → detail: Channels Organization (Pattern)
R2. **One channel per concept.** One channel class per domain concept, living in `app/channels/`. → detail: Channels Organization (Pattern)
R3. **stream_for domain instances.** Channels stream with `stream_for` on domain instances, not raw string stream names. → detail: Channels Organization (Pattern)
R4. **Thin channels.** Client actions delegate to Operations; channels contain no business logic. → detail: references/channels.md
R5. **Broadcast from operations.** Broadcasts happen inside Operations after a successful state change. → detail: Operations Broadcasting (Pattern)
R6. **Typed JSON payloads.** Messages are JSON with a `type` and small deltas, and broadcasts include a timestamp. → detail: Messages (Pattern)
R7. **Verified connection.** `ApplicationCable::Connection` identifies `current_user` and calls `reject_unauthorized_connection` when unverified. → detail: references/channels.md

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

