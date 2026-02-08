# Realtime Skill (Action Cable + Trailblazer 2.1)

**Reference: [VERIFICATION_CHECKLIST.md](../../VERIFICATION_CHECKLIST.md)**

This skill provides patterns for real-time communication. For complete project guidelines, see the verification checklist.

## Dependencies
- actioncable
- trailblazer-operation
- trailblazer-rails

## Channels Organization
- Live in `app/channels/`
- One channel per game/room.
- Authorize in `subscribed`.
- Use `stream_for` with game instance.
- Keep channel minimal; delegate to Operations in `app/concepts/`.

## Messages
- JSON payloads with `type` and small deltas.
- Include timestamps in broadcasts.

## Operations Broadcasting
- Broadcast inside Operations (in `app/concepts/{domain}/operation/`) after successful state changes.
- Example: `Game::BroadcastChannel.broadcast_to(game, { type: 'player_moved', ... })`

