CC     := gcc
CFLAGS := -Wall -Wextra -Wfloat-equal -O2 -D_GNU_SOURCE -I../include -I../common/include

SRC := main.c
OBJ := obj/main.o

all: dirs $(OBJ)

dirs:
	mkdir -p obj

$(OBJ): $(SRC)
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -rf obj

.PHONY: all clean dirs