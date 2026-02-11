# Realtime Skill (Action Cable + Trailblazer 2.1)

**Reference: [VERIFICATION_CHECKLIST.md](../../VERIFICATION_CHECKLIST.md)**

This skill provides patterns for real-time communication. For complete project guidelines, see the verification checklist.

## Dependencies
- actioncable
- trailblazer-operation
- trailblazer-rails

## Channels Organization (Pattern)
- `app/channels/` hosts channel classes
- One channel per domain concept (game/room)
- Authorization happens in `subscribed`
- Use `stream_for` with domain instances
- Keep channels thin and delegate logic to Operations

## Messages (Pattern)
- JSON payloads with `type` and small deltas
- Include timestamps in broadcasts

## Operations Broadcasting (Pattern)
- Broadcast inside Operations after successful state changes
- Example: `Game::BroadcastChannel.broadcast_to(game, { type: 'player_moved', ... })`

See [Channels](../../VERIFICATION_CHECKLIST.md#channels-action-cable) for requirements.

