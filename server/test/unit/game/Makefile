CC     := gcc
CFLAGS := -std=c17 -Wall -Wextra -Wfloat-equal -Wno-float-equal -O2 -D_GNU_SOURCE \
          -I../../../game/include \
          -I../../../common/include

SRC := $(wildcard *.c)
OBJ := $(addprefix obj/, $(notdir $(SRC:.c=.o)))

all: dirs $(OBJ)

dirs:
	mkdir -p obj

obj/%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -rf obj

.PHONY: all dirs clean
