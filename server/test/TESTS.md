# Server Tests

All commands run from `server/`.

Set the target IP in the relevant `test-config.h` before running integration tests:
- `test/integration/supervisor/test-config.h` — supervisor tests
- `test/integration/game/test-config.h` — game test

---

## Integration Tests

### Orchestrator

Verifies the supervisor orchestrator handles TCP input correctly. Two variants: one sends full packets, the other sends data in small chunks to exercise partial-packet reassembly.

| Command | Description |
|---|---|
| `make test-orchestrator` | Launches supervisor, runs both orchestrator tests |
| `make test-orchestrator-remote` | Runs tests against an already-running supervisor |

### Matchmaker

Verifies clients are matched into games. `test_matchmaking` checks the basic match flow; `test_matchmaking_queue` checks that clients queued while all ports are full are matched once ports free up, including across uneven batches.

| Command | Description |
|---|---|
| `make test-matchmaker` | Launches supervisor, runs matchmaking test |
| `make test-matchmaker-remote` | Runs matchmaking test against an already-running supervisor |
| `make test-matchmaking-queue-remote` | Runs the queue-exhaustion test against an already-running supervisor |

`./bin/test_matchmaking [num_clients [ip]]` — defaults: 10 clients, `IP_ADDRESS`

### Game

Forks the game binary directly and connects multiple clients through a full game session.

| Command | Description |
|---|---|
| `make test-game` | Builds and runs the game integration test |

---

## Unit Tests

Run all unit tests at once:

```
make test-unit
```

### Port Reaper

Tests the `PortManager` reaper thread in isolation — no running server needed. Verifies ports are reclaimed after a child process exits and that the reaper survives unknown PIDs.

| Command | Description |
|---|---|
| `make test-port-reaper` | Builds and runs the port reaper unit test |

### Game

Tests `game.c` and `player.c` without a running server or map file. Constructs `Game` and `Player` structs manually and covers:

- `create_player` / `destroy_player` — allocation, field initialisation
- `add_player` — correct slot assignment, initial position copied from game
- `update_player` — all fields (pos, vel, score) updated from packet
- `update_game` — routes update to matching player by ID; ignores non-zero control; no crash on unknown player ID
- `update_game_tick` / `update_game_status` — setter correctness
- `form_auth_packet` / `form_init_packet` — header fields, payload size, and all player records verified

| Command | Description |
|---|---|
| `make test-game-unit` | Builds and runs the game unit test |
