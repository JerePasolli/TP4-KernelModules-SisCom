TARGET = hello_world
SRCS = hello_world.c
CC = gcc
CFLAGS = -Wall -Werror

all: $(TARGET)

$(TARGET): $(SRCS)
	$(CC) $(CFLAGS) -o $(TARGET) $(SRCS)

install: $(TARGET)
	install -m 0755 $(TARGET) /usr/local/bin/

clean:
	rm -f $(TARGET)
	