extends Object

var udp: PacketPeerUDP

func init(ip: String, port: int) -> bool:
	if udp:
		udp.close()

	udp = PacketPeerUDP.new()

	var err := udp.bind(0)
	if err != OK:
		push_error("UDP init failed: %s" % err)
		return false

	udp.set_dest_address(ip, port)
	return true

func send(packet: PackedByteArray) -> bool:
	if not udp:
		return false

	if packet.is_empty():
		return false

	var err := udp.put_packet(packet)
	return err == OK

func receive() -> PackedByteArray:
	if not udp:
		return PackedByteArray()

	if udp.get_available_packet_count() <= 0:
		return PackedByteArray()

	var packet := udp.get_packet()
	var err := udp.get_packet_error()

	if err != OK:
		return PackedByteArray()

	return packet

func close() -> void:
	if udp:
		udp.close()
	udp = null
