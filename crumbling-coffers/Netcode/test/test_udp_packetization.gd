extends GutTest


# ── Helpers ──────────────────────────────────────────────────────────────────

const GAME_ID   := "AABBCCDDEEFF00112233445566778899"
const PLAYER_ID := "00112233445566778899AABBCCDDEEFF"
const TEST_PORT := 7000

func _decode_u16_le(buf: PackedByteArray, off: int) -> int:
	return buf[off] | (buf[off + 1] << 8)

func _decode_u32_le(buf: PackedByteArray, off: int) -> int:
	return buf[off] | (buf[off+1] << 8) | (buf[off+2] << 16) | (buf[off+3] << 24)

func _decode_i32_le(buf: PackedByteArray, off: int) -> int:
	var u := _decode_u32_le(buf, off)
	return u if u < 0x80000000 else u - 0x100000000

func _encode_f32_le(value: float, buf: PackedByteArray, off: int) -> void:
	var tmp := PackedFloat32Array([value]).to_byte_array()
	buf[off] = tmp[0]; buf[off + 1] = tmp[1]; buf[off + 2] = tmp[2]; buf[off + 3] = tmp[3]

func _decode_f32_le(buf: PackedByteArray, off: int) -> float:
	var tmp := PackedByteArray([buf[off], buf[off + 1], buf[off + 2], buf[off + 3]])
	return tmp.to_float32_array()[0]

func _hex_bytes_match(buf: PackedByteArray, off: int, hex: String) -> bool:
	for i in range(16):
		if buf[off + i] != hex.substr(i * 2, 2).hex_to_int():
			return false
	return true

# Builds a raw SERVER_INIT packet for interpret_udp_packet tests.
func _make_server_init_raw(start_tick: int, stop_tick: int,
		players: Array) -> PackedByteArray:
	# players: Array of {id: String, x: int, y: int}
	var HDR := PacketizationManager.UDP_HDR_SIZE
	var raw := PackedByteArray()
	raw.resize(PacketizationManager.PACKET_SIZE)
	raw.fill(0)
	raw[PacketizationManager.UDP_HDR_CTRL_OFFSET    ] = PacketizationManager.UDP_CTRL_SERVER_INIT & 0xFF
	raw[PacketizationManager.UDP_HDR_CTRL_OFFSET + 1] = (PacketizationManager.UDP_CTRL_SERVER_INIT >> 8) & 0xFF
	raw[PacketizationManager.UDP_HDR_SEQ_NUM_OFFSET] = 42
	raw[HDR    ] =  start_tick        & 0xFF
	raw[HDR + 1] = (start_tick >>  8) & 0xFF
	raw[HDR + 2] = (start_tick >> 16) & 0xFF
	raw[HDR + 3] = (start_tick >> 24) & 0xFF
	raw[HDR + 4] =  stop_tick        & 0xFF
	raw[HDR + 5] = (stop_tick >>  8) & 0xFF
	raw[HDR + 6] = (stop_tick >> 16) & 0xFF
	raw[HDR + 7] = (stop_tick >> 24) & 0xFF
	raw[HDR + 8] = players.size()
	for i in range(players.size()):
		var base := HDR + 9 + i * 24
		var pid: String = players[i].id
		for j in range(16):
			raw[base + j] = pid.substr(j * 2, 2).hex_to_int()
		_encode_f32_le(players[i].x, raw, base + 16)
		_encode_f32_le(players[i].y, raw, base + 20)
	return raw

# Builds a raw SERVER_AUTH packet for interpret_udp_packet tests.
func _make_server_auth_raw(seq_num: int, players: Array, start_tick: int = 0, stop_tick: int = 0) -> PackedByteArray:
	# players: Array of {id: String, pos_x, pos_y, vel_x, vel_y, score}
	var HDR := PacketizationManager.UDP_HDR_SIZE
	var raw := PackedByteArray()
	raw.resize(PacketizationManager.PACKET_SIZE)
	raw.fill(0)
	raw[PacketizationManager.UDP_HDR_CTRL_OFFSET    ] = PacketizationManager.UDP_CTRL_SERVER_AUTH & 0xFF
	raw[PacketizationManager.UDP_HDR_CTRL_OFFSET + 1] = (PacketizationManager.UDP_CTRL_SERVER_AUTH >> 8) & 0xFF
	raw[PacketizationManager.UDP_HDR_SEQ_NUM_OFFSET    ] =  seq_num        & 0xFF
	raw[PacketizationManager.UDP_HDR_SEQ_NUM_OFFSET + 1] = (seq_num >>  8) & 0xFF
	raw[PacketizationManager.UDP_HDR_SEQ_NUM_OFFSET + 2] = (seq_num >> 16) & 0xFF
	raw[PacketizationManager.UDP_HDR_SEQ_NUM_OFFSET + 3] = (seq_num >> 24) & 0xFF
	raw[HDR    ] =  start_tick        & 0xFF
	raw[HDR + 1] = (start_tick >>  8) & 0xFF
	raw[HDR + 2] = (start_tick >> 16) & 0xFF
	raw[HDR + 3] = (start_tick >> 24) & 0xFF
	raw[HDR + 4] =  stop_tick        & 0xFF
	raw[HDR + 5] = (stop_tick >>  8) & 0xFF
	raw[HDR + 6] = (stop_tick >> 16) & 0xFF
	raw[HDR + 7] = (stop_tick >> 24) & 0xFF
	raw[HDR + 8] = players.size()
	for i in range(players.size()):
		var base := HDR + 9 + i * 36
		var pid: String = players[i].id
		for j in range(16):
			raw[base + j] = pid.substr(j * 2, 2).hex_to_int()
		_encode_f32_le(players[i].pos_x, raw, base + 16)
		_encode_f32_le(players[i].pos_y, raw, base + 20)
		_encode_f32_le(players[i].vel_x, raw, base + 24)
		_encode_f32_le(players[i].vel_y, raw, base + 28)
		var sc: int = players[i].score
		raw[base + 32] =  sc        & 0xFF
		raw[base + 33] = (sc >>  8) & 0xFF
		raw[base + 34] = (sc >> 16) & 0xFF
		raw[base + 35] = (sc >> 24) & 0xFF
	return raw


# ── form_udp_init_packet ─────────────────────────────────────────────────────

func test_init_packet_is_correct_size() -> void:
	var udp_pkt: Object = PacketizationManager.form_udp_init_packet(GAME_ID, PLAYER_ID, TEST_PORT)
	assert_eq(udp_pkt.payload.size(), PacketizationManager.PACKET_SIZE,
		"INIT packet payload must be PACKET_SIZE bytes")

func test_init_packet_port() -> void:
	var udp_pkt: Object = PacketizationManager.form_udp_init_packet(GAME_ID, PLAYER_ID, TEST_PORT)
	assert_eq(udp_pkt.port, TEST_PORT, "UDPPacket.port must match the port argument")

func test_init_packet_game_id_bytes() -> void:
	var udp_pkt: Object = PacketizationManager.form_udp_init_packet(GAME_ID, PLAYER_ID, TEST_PORT)
	assert_true(_hex_bytes_match(udp_pkt.payload, PacketizationManager.UDP_HDR_GAME_ID_OFFSET, GAME_ID),
		"game_id must be encoded at the correct header offset")

func test_init_packet_player_id_bytes() -> void:
	var udp_pkt: Object = PacketizationManager.form_udp_init_packet(GAME_ID, PLAYER_ID, TEST_PORT)
	assert_true(_hex_bytes_match(udp_pkt.payload, PacketizationManager.UDP_HDR_PLAYER_ID_OFFSET, PLAYER_ID),
		"player_id must be encoded at the correct header offset")

func test_init_packet_ctrl_field() -> void:
	var udp_pkt: Object = PacketizationManager.form_udp_init_packet(GAME_ID, PLAYER_ID, TEST_PORT)
	var ctrl := _decode_u16_le(udp_pkt.payload, PacketizationManager.UDP_HDR_CTRL_OFFSET)
	assert_eq(ctrl, PacketizationManager.UDP_CTRL_INIT,
		"ctrl field must be UDP_CTRL_INIT")

func test_init_packet_payload_size_field() -> void:
	var udp_pkt: Object = PacketizationManager.form_udp_init_packet(GAME_ID, PLAYER_ID, TEST_PORT)
	var payload_size := _decode_u16_le(udp_pkt.payload, PacketizationManager.UDP_HDR_PAYLOAD_SIZE_OFFSET)
	assert_eq(payload_size, PacketizationManager.UDP_INIT_PAYLOAD_SIZE,
		"payload_size field must be UDP_INIT_PAYLOAD_SIZE")

func test_init_packet_seq_num_is_zero() -> void:
	var udp_pkt: Object = PacketizationManager.form_udp_init_packet(GAME_ID, PLAYER_ID, TEST_PORT)
	var seq := _decode_u32_le(udp_pkt.payload, PacketizationManager.UDP_HDR_SEQ_NUM_OFFSET)
	assert_eq(seq, 0, "seq_num must be 0 for INIT packet")


# ── form_udp_reg_packet ──────────────────────────────────────────────────────

func test_reg_packet_is_correct_size() -> void:
	var udp_pkt: Object = PacketizationManager.form_udp_reg_packet(GAME_ID, PLAYER_ID, TEST_PORT,
		Vector2(10, 20), Vector2(3, -4), 99)
	assert_eq(udp_pkt.payload.size(), PacketizationManager.PACKET_SIZE,
		"Regular packet payload must be PACKET_SIZE bytes")

func test_reg_packet_ctrl_field() -> void:
	var udp_pkt: Object = PacketizationManager.form_udp_reg_packet(GAME_ID, PLAYER_ID, TEST_PORT,
		Vector2.ZERO, Vector2.ZERO, 0)
	var ctrl := _decode_u16_le(udp_pkt.payload, PacketizationManager.UDP_HDR_CTRL_OFFSET)
	assert_eq(ctrl, PacketizationManager.UDP_CTRL_REGULAR,
		"ctrl field must be UDP_CTRL_REGULAR")

func test_reg_packet_payload_size_field() -> void:
	var udp_pkt: Object = PacketizationManager.form_udp_reg_packet(GAME_ID, PLAYER_ID, TEST_PORT,
		Vector2.ZERO, Vector2.ZERO, 0)
	var payload_size := _decode_u16_le(udp_pkt.payload, PacketizationManager.UDP_HDR_PAYLOAD_SIZE_OFFSET)
	assert_eq(payload_size, PacketizationManager.UDP_REG_PAYLOAD_SIZE,
		"payload_size must be UDP_REG_PAYLOAD_SIZE")

func test_reg_packet_seq_num_is_zero() -> void:
	var udp_pkt: Object = PacketizationManager.form_udp_reg_packet(GAME_ID, PLAYER_ID, TEST_PORT,
		Vector2.ZERO, Vector2.ZERO, 0)
	var seq := _decode_u32_le(udp_pkt.payload, PacketizationManager.UDP_HDR_SEQ_NUM_OFFSET)
	assert_eq(seq, 0, "seq_num must be 0 (managed internally, not supplied by caller)")

func test_reg_packet_game_id_bytes() -> void:
	var udp_pkt: Object = PacketizationManager.form_udp_reg_packet(GAME_ID, PLAYER_ID, TEST_PORT,
		Vector2.ZERO, Vector2.ZERO, 0)
	assert_true(_hex_bytes_match(udp_pkt.payload, PacketizationManager.UDP_HDR_GAME_ID_OFFSET, GAME_ID),
		"game_id bytes must match")

func test_reg_packet_player_id_bytes() -> void:
	var udp_pkt: Object = PacketizationManager.form_udp_reg_packet(GAME_ID, PLAYER_ID, TEST_PORT,
		Vector2.ZERO, Vector2.ZERO, 0)
	assert_true(_hex_bytes_match(udp_pkt.payload, PacketizationManager.UDP_HDR_PLAYER_ID_OFFSET, PLAYER_ID),
		"player_id bytes must match")

func test_reg_packet_position_x() -> void:
	var udp_pkt: Object = PacketizationManager.form_udp_reg_packet(GAME_ID, PLAYER_ID, TEST_PORT,
		Vector2(123, 0), Vector2.ZERO, 0)
	var px := _decode_f32_le(udp_pkt.payload, PacketizationManager.UDP_HDR_SIZE)
	assert_eq(px, 123.0, "position.x must be encoded at HDR_SIZE offset")

func test_reg_packet_position_y() -> void:
	var udp_pkt: Object = PacketizationManager.form_udp_reg_packet(GAME_ID, PLAYER_ID, TEST_PORT,
		Vector2(0, 456), Vector2.ZERO, 0)
	var py := _decode_f32_le(udp_pkt.payload, PacketizationManager.UDP_HDR_SIZE + 4)
	assert_eq(py, 456.0, "position.y must be encoded at HDR_SIZE+4 offset")

func test_reg_packet_negative_velocity() -> void:
	var udp_pkt: Object = PacketizationManager.form_udp_reg_packet(GAME_ID, PLAYER_ID, TEST_PORT,
		Vector2.ZERO, Vector2(-7, -8), 0)
	var vx := _decode_f32_le(udp_pkt.payload, PacketizationManager.UDP_HDR_SIZE + 8)
	var vy := _decode_f32_le(udp_pkt.payload, PacketizationManager.UDP_HDR_SIZE + 12)
	assert_eq(vx, -7.0, "negative velocity.x must survive float encoding")
	assert_eq(vy, -8.0, "negative velocity.y must survive float encoding")

func test_reg_packet_score() -> void:
	var udp_pkt: Object = PacketizationManager.form_udp_reg_packet(GAME_ID, PLAYER_ID, TEST_PORT,
		Vector2.ZERO, Vector2.ZERO, 42)
	var score := _decode_u32_le(udp_pkt.payload, PacketizationManager.UDP_HDR_SIZE + 16)
	assert_eq(score, 42, "score must be encoded at HDR_SIZE+16 offset")


# ── interpret_udp_packet — wrong size ────────────────────────────────────────

func test_wrong_size_returns_error_status() -> void:
	var raw := PackedByteArray()
	raw.resize(PacketizationManager.PACKET_SIZE - 1)
	raw.fill(0)
	var resp: PacketizationManager.UDP_Response = PacketizationManager.interpret_udp_packet(raw)
	assert_eq(resp.status, PacketizationManager.UDPStatus.ERROR,
		"A packet of wrong size must yield ERROR status")


# ── interpret_udp_packet — unknown ctrl ──────────────────────────────────────

func test_unknown_ctrl_returns_error_status() -> void:
	var raw := PackedByteArray()
	raw.resize(PacketizationManager.PACKET_SIZE)
	raw.fill(0)
	raw[PacketizationManager.UDP_HDR_CTRL_OFFSET] = 0x01
	var resp: PacketizationManager.UDP_Response = PacketizationManager.interpret_udp_packet(raw)
	assert_eq(resp.status, PacketizationManager.UDPStatus.ERROR,
		"An unrecognised ctrl field must yield ERROR status")


# ── interpret_udp_packet — SERVER_INIT ───────────────────────────────────────

func test_server_init_packet_type() -> void:
	var raw := _make_server_init_raw(100, 200, [])
	var resp: PacketizationManager.UDP_Response = PacketizationManager.interpret_udp_packet(raw)
	assert_eq(resp.packet_type, PacketizationManager.UDPPacketType.SERVER_INIT,
		"packet_type must be SERVER_INIT")

func test_server_init_status_is_normal() -> void:
	var raw := _make_server_init_raw(100, 200, [])
	var resp: PacketizationManager.UDP_Response = PacketizationManager.interpret_udp_packet(raw)
	assert_eq(resp.status, PacketizationManager.UDPStatus.NORMAL,
		"Valid SERVER_INIT must have NORMAL status")

func test_server_init_server_cur_tick() -> void:
	var raw := _make_server_init_raw(100, 200, [])
	var resp: PacketizationManager.UDP_Response = PacketizationManager.interpret_udp_packet(raw)
	assert_eq(resp.server_cur_tick, 42, "server_cur_tick must equal seq_num from header")

func test_server_init_start_tick() -> void:
	var raw := _make_server_init_raw(100, 200, [])
	var resp: PacketizationManager.UDP_Response = PacketizationManager.interpret_udp_packet(raw)
	assert_eq(resp.start_tick, 100, "start_tick must be decoded correctly")

func test_server_init_stop_tick() -> void:
	var raw := _make_server_init_raw(100, 200, [])
	var resp: PacketizationManager.UDP_Response = PacketizationManager.interpret_udp_packet(raw)
	assert_eq(resp.stop_tick, 200, "stop_tick must be decoded correctly")

func test_server_init_num_players() -> void:
	var players := [
		{id = GAME_ID, x = 10, y = 20},
		{id = PLAYER_ID, x = -5, y = 30},
	]
	var raw := _make_server_init_raw(1, 2, players)
	var resp: PacketizationManager.UDP_Response = PacketizationManager.interpret_udp_packet(raw)
	assert_eq(resp.num_players, 2, "num_players must match encoded count")

func test_server_init_player_positions_populated() -> void:
	var players := [{id = GAME_ID, x = 77, y = -33}]
	var raw := _make_server_init_raw(1, 2, players)
	var resp: PacketizationManager.UDP_Response = PacketizationManager.interpret_udp_packet(raw)
	assert_true(resp.player_init_positions.has(GAME_ID),
		"player_init_positions must contain entry for the encoded player id")

func test_server_init_player_position_values() -> void:
	var players := [{id = GAME_ID, x = 77, y = -33}]
	var raw := _make_server_init_raw(1, 2, players)
	var resp: PacketizationManager.UDP_Response = PacketizationManager.interpret_udp_packet(raw)
	var pos: PacketizationManager.PlayerInitPos = resp.player_init_positions[GAME_ID]
	assert_eq(pos.x, 77.0,  "PlayerInitPos.x must decode correctly")
	assert_eq(pos.y, -33.0, "PlayerInitPos.y must decode correctly (negative)")


# ── interpret_udp_packet — SERVER_AUTH ───────────────────────────────────────

func test_server_auth_packet_type() -> void:
	var raw := _make_server_auth_raw(500, [])
	var resp: PacketizationManager.UDP_Response = PacketizationManager.interpret_udp_packet(raw)
	assert_eq(resp.packet_type, PacketizationManager.UDPPacketType.SERVER_AUTH,
		"packet_type must be SERVER_AUTH")

func test_server_auth_status_is_normal() -> void:
	var raw := _make_server_auth_raw(500, [])
	var resp: PacketizationManager.UDP_Response = PacketizationManager.interpret_udp_packet(raw)
	assert_eq(resp.status, PacketizationManager.UDPStatus.NORMAL,
		"Valid SERVER_AUTH must have NORMAL status")

func test_server_auth_server_cur_tick() -> void:
	var raw := _make_server_auth_raw(500, [])
	var resp: PacketizationManager.UDP_Response = PacketizationManager.interpret_udp_packet(raw)
	assert_eq(resp.server_cur_tick, 500, "server_cur_tick must equal seq_num from header")

func test_server_auth_num_players() -> void:
	var players := [
		{id = GAME_ID,   pos_x = 1, pos_y = 2, vel_x = 3, vel_y = 4, score = 5},
		{id = PLAYER_ID, pos_x = 6, pos_y = 7, vel_x = 8, vel_y = 9, score = 10},
	]
	var raw := _make_server_auth_raw(1, players)
	var resp: PacketizationManager.UDP_Response = PacketizationManager.interpret_udp_packet(raw)
	assert_eq(resp.num_players, 2, "num_players must match encoded count")

func test_server_auth_players_populated() -> void:
	var players := [{id = GAME_ID, pos_x = 10, pos_y = 20,
					 vel_x = -1, vel_y = -2, score = 99}]
	var raw := _make_server_auth_raw(1, players)
	var resp: PacketizationManager.UDP_Response = PacketizationManager.interpret_udp_packet(raw)
	assert_true(resp.players.has(GAME_ID),
		"players dict must contain entry for the encoded player id")

func test_server_auth_player_info_values() -> void:
	var players := [{id = GAME_ID, pos_x = 10, pos_y = 20,
					 vel_x = -1, vel_y = -2, score = 99}]
	var raw := _make_server_auth_raw(1, players)
	var resp: PacketizationManager.UDP_Response = PacketizationManager.interpret_udp_packet(raw)
	var info: PacketizationManager.PlayerInfo = resp.players[GAME_ID]
	assert_eq(info.pos_x,  10.0, "PlayerInfo.pos_x must decode correctly")
	assert_eq(info.pos_y,  20.0, "PlayerInfo.pos_y must decode correctly")
	assert_eq(info.vel_x,  -1.0, "PlayerInfo.vel_x must decode correctly (negative)")
	assert_eq(info.vel_y,  -2.0, "PlayerInfo.vel_y must decode correctly (negative)")
	assert_eq(info.score,  99,   "PlayerInfo.score must decode correctly")

func test_server_auth_start_tick() -> void:
	var raw := _make_server_auth_raw(1, [], 100, 200)
	var resp: PacketizationManager.UDP_Response = PacketizationManager.interpret_udp_packet(raw)
	assert_eq(resp.start_tick, 100, "start_tick must decode correctly from SERVER_AUTH")

func test_server_auth_stop_tick() -> void:
	var raw := _make_server_auth_raw(1, [], 100, 200)
	var resp: PacketizationManager.UDP_Response = PacketizationManager.interpret_udp_packet(raw)
	assert_eq(resp.stop_tick, 200, "stop_tick must decode correctly from SERVER_AUTH")
