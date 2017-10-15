/*
 * Triggered instruction spatial coprocessor UIO driver. Based heavily on the TI OMAP PRU Subsystem
 * UIO driver by Amit Chatterjee and Pratheesh Gangadhar. The system is highly analogous: a
 * specialized programmable coprocessor with instruction memory accessible to the SoC host.
 */

#include <linux/device.h>
#include <linux/module.h>
#include <linux/moduleparam.h>
#include <linux/platform_device.h>
#include <linux/uio_driver.h>
#include <linux/platform_data/uio_pruss.h>
#include <linux/io.h>
#include <linux/clk.h>
#include <linux/dma-mapping.h>
#include <linux/sizes.h>
#include <linux/slab.h>
#include <linux/genalloc.h>

#define DRV_NAME "tia_ctrl_uio"
#define DRV_VERSION "0.1"

struct uio_tia_ctrl_dev {
    struct uio_info *info;
    void __iomem *tia_ctrl_vaddr;
};

static void tia_ctrl_cleanup(struct device *dev, struct uio_tia_ctrl_dev *gdev)
{
    struct uio_info *p;

    /* Get the generic device info, and unregister and free everything. */
    p = gdev->info;
    uio_unregister_device(p);
    kfree(p->name);
    iounmap(gdev->tia_ctrl_vaddr);
    kfree(gdev->info);
    kfree(gdev);
}

static int tia_ctrl_probe(struct platform_device *pdev)
{
    struct device *dev;
    struct uio_tia_ctrl_pdata *pdata;
    struct uio_tia_ctrl_dev *gdev;
    struct resource *tia_ctrl_io_region;
    struct uio_info *p;
    int ret, len;

    /* Get the device and platform data. */
    dev = &pdev->dev;
    pdata = dev_get_platdata(dev);

    /* Allocate the generic device. */
    gdev = kzalloc(sizeof(struct uio_tia_ctrl_dev), GFP_KERNEL);
    if (!gdev)
            return -ENOMEM;

    /* Allocate the generic device info. */
    gdev->info = kzalloc(sizeof(*p), GFP_KERNEL);
    if (!gdev->info) {
            kfree(gdev);
            return -ENOMEM;
    }

    /* Get access to the I/O region. */
    tia_ctrl_io_region = platform_get_resource(pdev, IORESOURCE_MEM, 0);
    if (!tia_ctrl_io_region) {
            dev_err(dev, "Unable to get I/O resource.\n");
            tia_ctrl_cleanup(dev, gdev);
            return -ENODEV;
    }

    /* Make sure the I/O reagion has a valid base address. */
    if (!tia_ctrl_io_region->start) {
            dev_err(dev, "Invalid memory resource.\n");
            tia_ctrl_cleanup(dev, gdev);
            return -ENODEV;
    }

    /* ioremap() the reported amount of I/O region memory. */
    len = resource_size(tia_ctrl_io_region);
    gdev->tia_ctrl_vaddr = ioremap(tia_ctrl_io_region->start, len);
    if (!gdev->tia_ctrl_vaddr) {
            dev_err(dev, "ioremap on TIA control registers failed.\n");
            tia_ctrl_cleanup(dev, gdev);
            return -ENODEV;
    }

    /* Fill in the device information. */
    p = gdev->info;
    p->mem[0].addr = tia_ctrl_io_region->start;
    p->mem[0].size = resource_size(tia_ctrl_io_region);
    p->mem[0].memtype = UIO_MEM_PHYS;
    p->name = kasprintf(GFP_KERNEL, "tia_ctrl_uio");
    p->version = DRV_VERSION;

    /* Register the device. */
    ret = uio_register_device(dev, p);
    if (ret < 0) {
        tia_ctrl_cleanup(dev, gdev);
        return ret;
    }
    platform_set_drvdata(pdev, gdev);

    /* Successful, if reached. */
    return 0;
}

static int tia_ctrl_remove(struct platform_device *dev)
{
    struct uio_tia_ctrl_dev *gdev;

    /* Get the platform data and remove the device. */
    gdev = platform_get_drvdata(dev);
    tia_ctrl_cleanup(&dev->dev, gdev);
    return 0;
}

static struct platform_driver tia_ctrl_driver = {
    .probe = tia_ctrl_probe,
    .remove = tia_ctrl_remove,
    .driver = {.name = DRV_NAME,},
};

module_platform_driver(tia_ctrl_driver);

MODULE_LICENSE("GPL v2");
MODULE_VERSION(DRV_VERSION);
MODULE_AUTHOR("Thomas J. Repetti trepetti@cs.columbia.edu");

