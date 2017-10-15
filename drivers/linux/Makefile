EXTRA_CFLAGS += -O2

KERNEL_DIR = ../../linux_image/source
PWD := $(shell pwd)
obj-m := tia_ctrl_uio.o

modules:
	$(MAKE) -C $(KERNEL_DIR) M=$(PWD) modules

clean:
	rm -rf *.o *~ core .depend .*.cmd *.ko *.mod.c .tmp_versions
