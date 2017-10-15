CFLAGS = -Wall -Wextra -Wunused -Werror -std=gnu11 -g -O2 -lm

SRC = src/pete.c
TARGET = pete

COMMON_DIR = ../common
COMMON_INC = $(COMMON_DIR)
COMMON_SRC = $(COMMON_DIR)/system_control.c $(COMMON_DIR)/processing_element.c $(COMMON_DIR)/io.c $(COMMON_DIR)/platform.c $(COMMON_DIR)/utility.c $(COMMON_DIR)/results.c

CJSON_DIR = ../lib/cJSON
CJSON_OBJ = $(CJSON_DIR)/libcjson.a
CJSON_INC = $(CJSON_DIR)

all: $(TARGET)

$(CJSON_OBJ):
	cd $(CJSON_DIR) && $(MAKE) libcjson.a

$(TARGET): $(SRC) $(CJSON_OBJ)
	$(CC) $(CFLAGS) -I$(COMMON_INC) -I$(CJSON_INC) -o $@ $(COMMON_SRC) $(SRC) $(CJSON_OBJ) # Statically link cJSON.

deploy: $(TARGET)
	sshpass -p root scp pete root@192.168.0.2:/home/root/pete

clean:
	rm -fv $(TARGET)
	cd $(CJSON_DIR) && make clean
