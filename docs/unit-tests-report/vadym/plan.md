# Unit Test Plan — Vadym

## 1. `server/test/unit/game` — Game & Player (C)

**File:** `server/test/unit/game/test_game_unit.c`
**Run:** `make test-game-unit` from `server/`

**Part of the project tested:** Server-side game state management — `game/src/game.c` and `game/src/player.c`. These modules are responsible for maintaining game state on the dedicated server (player positions, velocities, scores) and forming the UDP broadcast packets sent to all clients each tick.

**What each test verifies:**

| Test | What it checks |
|---|---|
| `create_player` returns non-NULL | Allocation succeeds |
| `create_player` copies player_id | `player_id` bytes match the input |
| `create_player` sets player_idx | `player_idx` field is stored correctly |
| `create_player` zeroes position | `pos_x` and `pos_y` start at 0 |
| `destroy_player` does not crash | Safe to free a valid player |
| `add_player` places player at correct index | Player is stored at `players[player_idx]` |
| `add_player` copies pos_x from initial_positions | Spawn position taken from game's map data |
| `add_player` copies pos_y from initial_positions | Spawn position taken from game's map data |
| `update_player` sets pos_x/pos_y/vel_x/vel_y/score | All five fields updated from incoming client packet |
| `update_game` updates matching player pos_x/pos_y/vel_x/vel_y/score | Packet routed to the correct player by player_id |
| `update_game` does not touch other player | Only the matching player is mutated |
| `update_game` ignores packet with non-zero control | Non-regular packets are rejected before any state change |
| `update_game` with unknown player_id does not crash | Unknown senders are silently ignored |
| `update_game_tick` sets game_tick | Tick counter updated correctly |
| `update_game_status` sets status | Game state machine transitions correctly |
| `form_auth_packet` — game_id, control flag, payload_size, seq_num | Header fields populated correctly from game state |
| `form_auth_packet` — start_tick, stop_tick, player count | Timing and lobby metadata correct |
| `form_auth_packet` — player[0] and player[1] id, pos_x, vel_x, score | Both player records fully encoded |
| `form_init_packet` — game_id, control flag, payload_size, seq_num | Header fields populated correctly |
| `form_init_packet` — start_tick, stop_tick, player count | Timing and lobby metadata correct |
| `form_init_packet` — player[0] and player[1] id, x, y | Both player spawn positions encoded |

---

## 2. `test_tcp_packetization.gd` — TCP Packetization (GDScript)

**File:** `crumbling-coffers/Netcode/test/test_tcp_packetization.gd`
**Run:** via GUT in the Godot editor

**Part of the project tested:** Client-side TCP communication layer — `PacketizationManager.gd`, specifically `form_tcp_packet` (outbound matchmaking requests from client to supervisor) and `interpret_tcp_packet` (inbound responses from supervisor to client).

**What each test verifies:**

| Test | What it checks |
|---|---|
| `test_tcp_packet_is_correct_size` | `form_tcp_packet` produces exactly `PACKET_SIZE` bytes |
| `test_tcp_packet_search_game_type_field` | `TYPE_SEARCH_GAME` encoded as little-endian uint32 in bytes [0:4] |
| `test_tcp_packet_stop_search_type_field` | `TYPE_STOP_SEARCH` encoded correctly in the same field |
| `test_tcp_packet_map_id_byte` | `map_id` stored in byte [4] |
| `test_tcp_packet_map_id_masked_to_byte` | `map_id` values wider than one byte are truncated with `& 0xFF` |
| `test_tcp_packet_remaining_bytes_are_zero` | All padding bytes after byte [4] are zero |
| `test_interpret_game_found_response_type` | `interpret_tcp_packet` sets `response_type` to `TYPE_GAME_FOUND` |
| `test_interpret_game_found_game_id` | 16-byte `game_id` round-trips through the packet encoding |
| `test_interpret_game_found_player_id` | 16-byte `player_id` round-trips through the packet encoding |
| `test_interpret_game_found_server_ip` | 4-byte big-endian IP decoded to dotted IPv4 string |
| `test_interpret_game_found_port` | Little-endian uint16 port decoded correctly |
| `test_interpret_game_not_found_response_type` | `response_type` set to `TYPE_GAME_NOT_FOUND` |
| `test_interpret_game_not_found_leaves_game_id_empty` | `game_id` not populated for a not-found response |

---

## 3. `test_udp_packetization.gd` — UDP Packetization (GDScript)

**File:** `crumbling-coffers/Netcode/test/test_udp_packetization.gd`
**Run:** via GUT in the Godot editor

**Part of the project tested:** Client-side UDP communication layer — `PacketizationManager.gd`, specifically `form_udp_init_packet` and `form_udp_reg_packet` (outbound packets from client to game server) and `interpret_udp_packet` (inbound SERVER_INIT and SERVER_AUTH broadcasts from game server to client).

**What each test verifies:**

| Test | What it checks |
|---|---|
| `test_init_packet_is_correct_size` | `form_udp_init_packet` produces exactly `PACKET_SIZE` bytes |
| `test_init_packet_port` | `UDPPacket.port` matches the argument |
| `test_init_packet_game_id_bytes` | `game_id` encoded at the correct header offset |
| `test_init_packet_player_id_bytes` | `player_id` encoded at the correct header offset |
| `test_init_packet_ctrl_field` | Control field set to `UDP_CTRL_INIT` |
| `test_init_packet_payload_size_field` | `payload_size` field set to `UDP_INIT_PAYLOAD_SIZE` |
| `test_init_packet_seq_num_is_zero` | `seq_num` is 0 for init packets |
| `test_reg_packet_is_correct_size` | `form_udp_reg_packet` produces exactly `PACKET_SIZE` bytes |
| `test_reg_packet_ctrl_field` | Control field set to `UDP_CTRL_REGULAR` |
| `test_reg_packet_payload_size_field` | `payload_size` field set to `UDP_REG_PAYLOAD_SIZE` |
| `test_reg_packet_seq_num_is_zero` | `seq_num` is 0 (managed internally) |
| `test_reg_packet_game_id_bytes` | `game_id` encoded at correct offset |
| `test_reg_packet_player_id_bytes` | `player_id` encoded at correct offset |
| `test_reg_packet_position_x` | `position.x` encoded as float32 LE at `HDR_SIZE` |
| `test_reg_packet_position_y` | `position.y` encoded as float32 LE at `HDR_SIZE+4` |
| `test_reg_packet_negative_velocity` | Negative `vel_x` and `vel_y` survive float32 encoding |
| `test_reg_packet_score` | `score` encoded as uint32 LE at `HDR_SIZE+16` |
| `test_wrong_size_returns_error_status` | Packet shorter than `PACKET_SIZE` yields `UDPStatus.ERROR` |
| `test_unknown_ctrl_returns_error_status` | Unrecognised control field yields `UDPStatus.ERROR` |
| `test_server_init_packet_type` | `interpret_udp_packet` sets `packet_type` to `SERVER_INIT` |
| `test_server_init_status_is_normal` | Valid SERVER_INIT yields `UDPStatus.NORMAL` |
| `test_server_init_server_cur_tick` | `server_cur_tick` equals `seq_num` from header |
| `test_server_init_start_tick` | `start_tick` decoded correctly |
| `test_server_init_stop_tick` | `stop_tick` decoded correctly |
| `test_server_init_num_players` | `num_players` matches encoded count |
| `test_server_init_player_positions_populated` | `player_init_positions` dict contains entry for each player |
| `test_server_init_player_position_values` | `PlayerInitPos.x` and `.y` decoded correctly (including negative) |
| `test_server_auth_packet_type` | `packet_type` set to `SERVER_AUTH` |
| `test_server_auth_status_is_normal` | Valid SERVER_AUTH yields `UDPStatus.NORMAL` |
| `test_server_auth_server_cur_tick` | `server_cur_tick` equals `seq_num` from header |
| `test_server_auth_num_players` | `num_players` matches encoded count |
| `test_server_auth_players_populated` | `players` dict contains entry for each player |
| `test_server_auth_player_info_values` | `PlayerInfo` pos, vel (including negatives), and score decoded correctly |
| `test_server_auth_start_tick` | `start_tick` decoded correctly from SERVER_AUTH |
| `test_server_auth_stop_tick` | `stop_tick` decoded correctly from SERVER_AUTH |
