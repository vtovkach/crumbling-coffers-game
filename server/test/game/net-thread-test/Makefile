CC = gcc
CFLAGS = -Wall -Wextra -std=c11 -O2

TARGET = net-thread-test
SRC = net-thread-test.c

BIN_DIR = bin
OBJ_DIR = obj

OBJ = $(OBJ_DIR)/udp_test_sender.o
BIN = $(BIN_DIR)/$(TARGET)

all: $(BIN)

$(BIN): $(OBJ) | $(BIN_DIR)
	$(CC) $(CFLAGS) -o $(BIN) $(OBJ)

$(OBJ): $(SRC) | $(OBJ_DIR)
	$(CC) $(CFLAGS) -c $(SRC) -o $(OBJ)

$(BIN_DIR):
	mkdir -p $(BIN_DIR)

$(OBJ_DIR):
	mkdir -p $(OBJ_DIR)

run: $(BIN)
	./$(BIN)

clean:
	rm -rf $(BIN_DIR) $(OBJ_DIR)

.PHONY: all run clean