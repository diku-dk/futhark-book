import pyopencl as cl

def PrintDeviceInfo(device):
    print "Name: %s" % device.name
    print "OpenCL version: %s" % device.version
    print "Global memory size: %.2f Megabytes" % (device.global_mem_size/1024/1024)
    print "Local memory size: %.2f Kilobytes" % (device.local_mem_size/1024)
    print "Max constant buffer size: %.2f Kilobytes" % (device.max_constant_buffer_size/1024)
    print "Max clock frequency: %i Hz" % device.max_clock_frequency
    print "Max compute units: %i" % device.max_compute_units
    print "Max work group size: %i" % device.max_work_group_size
    print "Max work item sizes: %s" % device.max_work_item_sizes

def PrintOpenCLInfo():
    for platform in cl.get_platforms():
        print "Platform: %s" % platform.name
        for device in platform.get_devices():
            PrintDeviceInfo(device)
        print ''

PrintOpenCLInfo()
