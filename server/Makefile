CC := gcc

SUPERVISOR_BIN := bin/supervisor
GAME_BIN       := bin/game
ORCH_BIN       := bin/orch

all: modules $(GAME_BIN) $(SUPERVISOR_BIN) $(ORCH_BIN)

modules:
	$(MAKE) -C common
	$(MAKE) -C game
	$(MAKE) -C orchestrator
	$(MAKE) -C supervisor

$(GAME_BIN): modules
	@mkdir -p bin
	$(CC) \
		$$(find game/obj -type f -name '*.o') \
		$$(find common/obj -type f -name '*.o') \
		-o $@

$(SUPERVISOR_BIN): modules
	@mkdir -p bin
	$(CC) \
		$$(find supervisor/obj -type f -name '*.o') \
		$$(find common/obj -type f -name '*.o') \
		-o $@

$(ORCH_BIN): modules
	@mkdir -p bin
	$(CC) \
		$$(find orchestrator/obj -type f -name '*.o') \
		$$(find common/obj -type f -name '*.o') \
		-o $@
	
run:
	./$(SUPERVISOR_BIN)

clean:
	$(MAKE) -C common clean
	$(MAKE) -C game clean
	$(MAKE) -C orchestrator clean
	$(MAKE) -C supervisor clean
	rm -rf bin

.PHONY: all modules clean