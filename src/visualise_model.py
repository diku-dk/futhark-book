import sys
import numpy as np
import ctypes as ct
# Stub code for OpenCL setup.

import pyopencl as cl

def get_prefered_context(interactive=False, platform_pref=None, device_pref=None):
    if interactive:
        return cl.create_some_context(interactive=True)

    def platform_ok(p):
        return not platform_pref or p.name.find(platform_pref) >= 0
    def device_ok(d):
        return not device_pref or d.name.find(device_pref) >= 0

    for p in cl.get_platforms():
        if not platform_ok(p):
            continue
        for d in p.get_devices():
            if not device_ok(d):
                continue
            return cl.Context(devices=[d])
    raise Exception('No OpenCL platform and device matching constraints found.')
import pyopencl.array
import time
import argparse
FUT_BLOCK_DIM = "16"
synchronous = False
preferred_platform = None
preferred_device = None
fut_opencl_src = """__kernel void dummy_kernel(__global unsigned char *dummy, int n)
{
    const int thread_gid = get_global_id(0);
    
    if (thread_gid >= n)
        return;
}
typedef char int8_t;
typedef short int16_t;
typedef int int32_t;
typedef long int64_t;
typedef uchar uint8_t;
typedef ushort uint16_t;
typedef uint uint32_t;
typedef ulong uint64_t;
#define ALIGNED_LOCAL_MEMORY(m,size) __local unsigned char m[size] __attribute__ ((align))
static inline int8_t add8(int8_t x, int8_t y)
{
    return x + y;
}
static inline int16_t add16(int16_t x, int16_t y)
{
    return x + y;
}
static inline int32_t add32(int32_t x, int32_t y)
{
    return x + y;
}
static inline int64_t add64(int64_t x, int64_t y)
{
    return x + y;
}
static inline int8_t sub8(int8_t x, int8_t y)
{
    return x - y;
}
static inline int16_t sub16(int16_t x, int16_t y)
{
    return x - y;
}
static inline int32_t sub32(int32_t x, int32_t y)
{
    return x - y;
}
static inline int64_t sub64(int64_t x, int64_t y)
{
    return x - y;
}
static inline int8_t mul8(int8_t x, int8_t y)
{
    return x * y;
}
static inline int16_t mul16(int16_t x, int16_t y)
{
    return x * y;
}
static inline int32_t mul32(int32_t x, int32_t y)
{
    return x * y;
}
static inline int64_t mul64(int64_t x, int64_t y)
{
    return x * y;
}
static inline uint8_t udiv8(uint8_t x, uint8_t y)
{
    return x / y;
}
static inline uint16_t udiv16(uint16_t x, uint16_t y)
{
    return x / y;
}
static inline uint32_t udiv32(uint32_t x, uint32_t y)
{
    return x / y;
}
static inline uint64_t udiv64(uint64_t x, uint64_t y)
{
    return x / y;
}
static inline uint8_t umod8(uint8_t x, uint8_t y)
{
    return x % y;
}
static inline uint16_t umod16(uint16_t x, uint16_t y)
{
    return x % y;
}
static inline uint32_t umod32(uint32_t x, uint32_t y)
{
    return x % y;
}
static inline uint64_t umod64(uint64_t x, uint64_t y)
{
    return x % y;
}
static inline int8_t sdiv8(int8_t x, int8_t y)
{
    int8_t q = x / y;
    int8_t r = x % y;
    
    return q - ((r != 0 && r < 0 != y < 0) ? 1 : 0);
}
static inline int16_t sdiv16(int16_t x, int16_t y)
{
    int16_t q = x / y;
    int16_t r = x % y;
    
    return q - ((r != 0 && r < 0 != y < 0) ? 1 : 0);
}
static inline int32_t sdiv32(int32_t x, int32_t y)
{
    int32_t q = x / y;
    int32_t r = x % y;
    
    return q - ((r != 0 && r < 0 != y < 0) ? 1 : 0);
}
static inline int64_t sdiv64(int64_t x, int64_t y)
{
    int64_t q = x / y;
    int64_t r = x % y;
    
    return q - ((r != 0 && r < 0 != y < 0) ? 1 : 0);
}
static inline int8_t smod8(int8_t x, int8_t y)
{
    int8_t r = x % y;
    
    return r + (r == 0 || (x > 0 && y > 0) || (x < 0 && y < 0) ? 0 : y);
}
static inline int16_t smod16(int16_t x, int16_t y)
{
    int16_t r = x % y;
    
    return r + (r == 0 || (x > 0 && y > 0) || (x < 0 && y < 0) ? 0 : y);
}
static inline int32_t smod32(int32_t x, int32_t y)
{
    int32_t r = x % y;
    
    return r + (r == 0 || (x > 0 && y > 0) || (x < 0 && y < 0) ? 0 : y);
}
static inline int64_t smod64(int64_t x, int64_t y)
{
    int64_t r = x % y;
    
    return r + (r == 0 || (x > 0 && y > 0) || (x < 0 && y < 0) ? 0 : y);
}
static inline int8_t squot8(int8_t x, int8_t y)
{
    return x / y;
}
static inline int16_t squot16(int16_t x, int16_t y)
{
    return x / y;
}
static inline int32_t squot32(int32_t x, int32_t y)
{
    return x / y;
}
static inline int64_t squot64(int64_t x, int64_t y)
{
    return x / y;
}
static inline int8_t srem8(int8_t x, int8_t y)
{
    return x % y;
}
static inline int16_t srem16(int16_t x, int16_t y)
{
    return x % y;
}
static inline int32_t srem32(int32_t x, int32_t y)
{
    return x % y;
}
static inline int64_t srem64(int64_t x, int64_t y)
{
    return x % y;
}
static inline uint8_t shl8(uint8_t x, uint8_t y)
{
    return x << y;
}
static inline uint16_t shl16(uint16_t x, uint16_t y)
{
    return x << y;
}
static inline uint32_t shl32(uint32_t x, uint32_t y)
{
    return x << y;
}
static inline uint64_t shl64(uint64_t x, uint64_t y)
{
    return x << y;
}
static inline uint8_t lshr8(uint8_t x, uint8_t y)
{
    return x >> y;
}
static inline uint16_t lshr16(uint16_t x, uint16_t y)
{
    return x >> y;
}
static inline uint32_t lshr32(uint32_t x, uint32_t y)
{
    return x >> y;
}
static inline uint64_t lshr64(uint64_t x, uint64_t y)
{
    return x >> y;
}
static inline int8_t ashr8(int8_t x, int8_t y)
{
    return x >> y;
}
static inline int16_t ashr16(int16_t x, int16_t y)
{
    return x >> y;
}
static inline int32_t ashr32(int32_t x, int32_t y)
{
    return x >> y;
}
static inline int64_t ashr64(int64_t x, int64_t y)
{
    return x >> y;
}
static inline uint8_t and8(uint8_t x, uint8_t y)
{
    return x & y;
}
static inline uint16_t and16(uint16_t x, uint16_t y)
{
    return x & y;
}
static inline uint32_t and32(uint32_t x, uint32_t y)
{
    return x & y;
}
static inline uint64_t and64(uint64_t x, uint64_t y)
{
    return x & y;
}
static inline uint8_t or8(uint8_t x, uint8_t y)
{
    return x | y;
}
static inline uint16_t or16(uint16_t x, uint16_t y)
{
    return x | y;
}
static inline uint32_t or32(uint32_t x, uint32_t y)
{
    return x | y;
}
static inline uint64_t or64(uint64_t x, uint64_t y)
{
    return x | y;
}
static inline uint8_t xor8(uint8_t x, uint8_t y)
{
    return x ^ y;
}
static inline uint16_t xor16(uint16_t x, uint16_t y)
{
    return x ^ y;
}
static inline uint32_t xor32(uint32_t x, uint32_t y)
{
    return x ^ y;
}
static inline uint64_t xor64(uint64_t x, uint64_t y)
{
    return x ^ y;
}
static inline char ult8(uint8_t x, uint8_t y)
{
    return x < y;
}
static inline char ult16(uint16_t x, uint16_t y)
{
    return x < y;
}
static inline char ult32(uint32_t x, uint32_t y)
{
    return x < y;
}
static inline char ult64(uint64_t x, uint64_t y)
{
    return x < y;
}
static inline char ule8(uint8_t x, uint8_t y)
{
    return x <= y;
}
static inline char ule16(uint16_t x, uint16_t y)
{
    return x <= y;
}
static inline char ule32(uint32_t x, uint32_t y)
{
    return x <= y;
}
static inline char ule64(uint64_t x, uint64_t y)
{
    return x <= y;
}
static inline char slt8(int8_t x, int8_t y)
{
    return x < y;
}
static inline char slt16(int16_t x, int16_t y)
{
    return x < y;
}
static inline char slt32(int32_t x, int32_t y)
{
    return x < y;
}
static inline char slt64(int64_t x, int64_t y)
{
    return x < y;
}
static inline char sle8(int8_t x, int8_t y)
{
    return x <= y;
}
static inline char sle16(int16_t x, int16_t y)
{
    return x <= y;
}
static inline char sle32(int32_t x, int32_t y)
{
    return x <= y;
}
static inline char sle64(int64_t x, int64_t y)
{
    return x <= y;
}
static inline int8_t pow8(int8_t x, int8_t y)
{
    int8_t res = 1, rem = y;
    
    while (rem != 0) {
        if (rem & 1)
            res *= x;
        rem >>= 1;
        x *= x;
    }
    return res;
}
static inline int16_t pow16(int16_t x, int16_t y)
{
    int16_t res = 1, rem = y;
    
    while (rem != 0) {
        if (rem & 1)
            res *= x;
        rem >>= 1;
        x *= x;
    }
    return res;
}
static inline int32_t pow32(int32_t x, int32_t y)
{
    int32_t res = 1, rem = y;
    
    while (rem != 0) {
        if (rem & 1)
            res *= x;
        rem >>= 1;
        x *= x;
    }
    return res;
}
static inline int64_t pow64(int64_t x, int64_t y)
{
    int64_t res = 1, rem = y;
    
    while (rem != 0) {
        if (rem & 1)
            res *= x;
        rem >>= 1;
        x *= x;
    }
    return res;
}
static inline int8_t sext_i8_i8(int8_t x)
{
    return x;
}
static inline int16_t sext_i8_i16(int8_t x)
{
    return x;
}
static inline int32_t sext_i8_i32(int8_t x)
{
    return x;
}
static inline int64_t sext_i8_i64(int8_t x)
{
    return x;
}
static inline int8_t sext_i16_i8(int16_t x)
{
    return x;
}
static inline int16_t sext_i16_i16(int16_t x)
{
    return x;
}
static inline int32_t sext_i16_i32(int16_t x)
{
    return x;
}
static inline int64_t sext_i16_i64(int16_t x)
{
    return x;
}
static inline int8_t sext_i32_i8(int32_t x)
{
    return x;
}
static inline int16_t sext_i32_i16(int32_t x)
{
    return x;
}
static inline int32_t sext_i32_i32(int32_t x)
{
    return x;
}
static inline int64_t sext_i32_i64(int32_t x)
{
    return x;
}
static inline int8_t sext_i64_i8(int64_t x)
{
    return x;
}
static inline int16_t sext_i64_i16(int64_t x)
{
    return x;
}
static inline int32_t sext_i64_i32(int64_t x)
{
    return x;
}
static inline int64_t sext_i64_i64(int64_t x)
{
    return x;
}
static inline uint8_t zext_i8_i8(uint8_t x)
{
    return x;
}
static inline uint16_t zext_i8_i16(uint8_t x)
{
    return x;
}
static inline uint32_t zext_i8_i32(uint8_t x)
{
    return x;
}
static inline uint64_t zext_i8_i64(uint8_t x)
{
    return x;
}
static inline uint8_t zext_i16_i8(uint16_t x)
{
    return x;
}
static inline uint16_t zext_i16_i16(uint16_t x)
{
    return x;
}
static inline uint32_t zext_i16_i32(uint16_t x)
{
    return x;
}
static inline uint64_t zext_i16_i64(uint16_t x)
{
    return x;
}
static inline uint8_t zext_i32_i8(uint32_t x)
{
    return x;
}
static inline uint16_t zext_i32_i16(uint32_t x)
{
    return x;
}
static inline uint32_t zext_i32_i32(uint32_t x)
{
    return x;
}
static inline uint64_t zext_i32_i64(uint32_t x)
{
    return x;
}
static inline uint8_t zext_i64_i8(uint64_t x)
{
    return x;
}
static inline uint16_t zext_i64_i16(uint64_t x)
{
    return x;
}
static inline uint32_t zext_i64_i32(uint64_t x)
{
    return x;
}
static inline uint64_t zext_i64_i64(uint64_t x)
{
    return x;
}
static inline float fdiv32(float x, float y)
{
    return x / y;
}
static inline float fadd32(float x, float y)
{
    return x + y;
}
static inline float fsub32(float x, float y)
{
    return x - y;
}
static inline float fmul32(float x, float y)
{
    return x * y;
}
static inline float fpow32(float x, float y)
{
    return pow(x, y);
}
static inline char cmplt32(float x, float y)
{
    return x < y;
}
static inline char cmple32(float x, float y)
{
    return x <= y;
}
static inline float sitofp_i8_f32(int8_t x)
{
    return x;
}
static inline float sitofp_i16_f32(int16_t x)
{
    return x;
}
static inline float sitofp_i32_f32(int32_t x)
{
    return x;
}
static inline float sitofp_i64_f32(int64_t x)
{
    return x;
}
static inline float uitofp_i8_f32(uint8_t x)
{
    return x;
}
static inline float uitofp_i16_f32(uint16_t x)
{
    return x;
}
static inline float uitofp_i32_f32(uint32_t x)
{
    return x;
}
static inline float uitofp_i64_f32(uint64_t x)
{
    return x;
}
static inline int8_t fptosi_f32_i8(float x)
{
    return x;
}
static inline int16_t fptosi_f32_i16(float x)
{
    return x;
}
static inline int32_t fptosi_f32_i32(float x)
{
    return x;
}
static inline int64_t fptosi_f32_i64(float x)
{
    return x;
}
static inline uint8_t fptoui_f32_i8(float x)
{
    return x;
}
static inline uint16_t fptoui_f32_i16(float x)
{
    return x;
}
static inline uint32_t fptoui_f32_i32(float x)
{
    return x;
}
static inline uint64_t fptoui_f32_i64(float x)
{
    return x;
}
static inline float futhark_sin32(float x)
{
    return sin(x);
}
static inline float futhark_cos32(float x)
{
    return cos(x);
}
__kernel void map_kernel_898(__global unsigned char *mem_912, float y_749,
                             int32_t width_743)
{
    int32_t wave_sizze_919;
    int32_t group_sizze_920;
    char thread_active_921;
    int32_t gtid_892;
    int32_t group_id_900;
    int32_t global_tid_898;
    int32_t local_tid_899;
    
    global_tid_898 = get_global_id(0);
    local_tid_899 = get_local_id(0);
    group_sizze_920 = get_local_size(0);
    wave_sizze_919 = LOCKSTEP_WIDTH;
    group_id_900 = get_group_id(0);
    gtid_892 = global_tid_898;
    thread_active_921 = slt32(gtid_892, width_743);
    
    float x_902;
    float res_903;
    float res_904;
    
    if (thread_active_921) {
        x_902 = sitofp_i32_f32(gtid_892);
        res_903 = x_902 / y_749;
        res_904 = res_903 * 30.0F;
    }
    if (thread_active_921) {
        *(__global float *) &mem_912[gtid_892 * 4] = res_904;
    }
}
__kernel void map_kernel_839(__global unsigned char *mem_912,
                             int32_t height_744, float res_754, float y_750,
                             int32_t degree_746, __global
                             unsigned char *mem_915, int32_t width_743)
{
    int32_t wave_sizze_922;
    int32_t group_sizze_923;
    char thread_active_924;
    int32_t gtid_832;
    int32_t local_tid_840;
    int32_t group_id_841;
    int32_t gtid_831;
    int32_t global_tid_839;
    
    global_tid_839 = get_global_id(0);
    local_tid_840 = get_local_id(0);
    group_sizze_923 = get_local_size(0);
    wave_sizze_922 = LOCKSTEP_WIDTH;
    group_id_841 = get_group_id(0);
    gtid_831 = squot32(global_tid_839, height_744);
    gtid_832 = global_tid_839 - squot32(global_tid_839, height_744) *
        height_744;
    thread_active_924 = slt32(gtid_831, width_743) && slt32(gtid_832,
                                                            height_744);
    
    float res_842;
    float x_844;
    float res_845;
    float res_846;
    
    if (thread_active_924) {
        res_842 = *(__global float *) &mem_912[gtid_831 * 4];
        x_844 = sitofp_i32_f32(gtid_832);
        res_845 = x_844 / y_750;
        res_846 = res_845 * 30.0F;
    }
    
    float res_847;
    float binop_param_x_850 = 0.0F;
    int32_t chunk_sizze_848;
    int32_t chunk_offset_849 = 0;
    
    chunk_sizze_848 = degree_746;
    
    float res_852;
    float acc_855 = binop_param_x_850;
    int32_t dummy_chunk_sizze_853 = 1;
    
    if (thread_active_924) {
        if (chunk_sizze_848 == degree_746) {
            for (int32_t i_854 = 0; i_854 < degree_746; i_854++) {
                int32_t iota_start_908;
                float x_859;
                float arg_860;
                float res_861;
                float res_862;
                float x_863;
                float y_864;
                float arg_865;
                float x_866;
                float x_867;
                float res_868;
                float res_869;
                
                iota_start_908 = i_854 + chunk_offset_849;
                x_859 = sitofp_i32_f32(iota_start_908);
                arg_860 = x_859 * res_754;
                res_861 = futhark_cos32(arg_860);
                res_862 = futhark_sin32(arg_860);
                x_863 = res_861 * res_846;
                y_864 = res_862 * res_842;
                arg_865 = x_863 + y_864;
                x_866 = futhark_cos32(arg_865);
                x_867 = x_866 + 1.0F;
                res_868 = x_867 / 2.0F;
                res_869 = acc_855 + res_868;
                acc_855 = res_869;
            }
        } else {
            for (int32_t i_854 = 0; i_854 < chunk_sizze_848; i_854++) {
                int32_t iota_start_908;
                float x_859;
                float arg_860;
                float res_861;
                float res_862;
                float x_863;
                float y_864;
                float arg_865;
                float x_866;
                float x_867;
                float res_868;
                float res_869;
                
                iota_start_908 = i_854 + chunk_offset_849;
                x_859 = sitofp_i32_f32(iota_start_908);
                arg_860 = x_859 * res_754;
                res_861 = futhark_cos32(arg_860);
                res_862 = futhark_sin32(arg_860);
                x_863 = res_861 * res_846;
                y_864 = res_862 * res_842;
                arg_865 = x_863 + y_864;
                x_866 = futhark_cos32(arg_865);
                x_867 = x_866 + 1.0F;
                res_868 = x_867 / 2.0F;
                res_869 = acc_855 + res_868;
                acc_855 = res_869;
            }
        }
    }
    res_852 = acc_855;
    binop_param_x_850 = res_852;
    res_847 = binop_param_x_850;
    
    int32_t tofloat_arg_870;
    float y_871;
    float res_872;
    int32_t res_873;
    int32_t res_874;
    float x_875;
    float y_876;
    float x_877;
    float x_878;
    float y_879;
    float res_880;
    float y_881;
    float res_882;
    float trunc_arg_883;
    int8_t res_884;
    int32_t x_885;
    int32_t y_886;
    int32_t x_887;
    float trunc_arg_888;
    int8_t res_889;
    int32_t y_890;
    int32_t res_891;
    
    if (thread_active_924) {
        tofloat_arg_870 = fptosi_f32_i32(res_847);
        y_871 = sitofp_i32_f32(tofloat_arg_870);
        res_872 = res_847 - y_871;
        res_873 = tofloat_arg_870 & 1;
        res_874 = 1 - res_873;
        x_875 = sitofp_i32_f32(res_873);
        y_876 = 1.0F - res_872;
        x_877 = x_875 * y_876;
        x_878 = sitofp_i32_f32(res_874);
        y_879 = x_878 * res_872;
        res_880 = x_877 + y_879;
        y_881 = res_880 * 0.6000000238418579F;
        res_882 = 0.4000000059604645F + y_881;
        trunc_arg_883 = 255.0F * res_882;
        res_884 = fptoui_f32_i8(trunc_arg_883);
        x_885 = zext_i8_i32(res_884);
        y_886 = x_885 << 8;
        x_887 = 16711680 | y_886;
        trunc_arg_888 = 255.0F * res_880;
        res_889 = fptoui_f32_i8(trunc_arg_888);
        y_890 = zext_i8_i32(res_889);
        res_891 = x_887 | y_890;
    }
    if (thread_active_924) {
        *(__global int32_t *) &mem_915[(gtid_831 * height_744 + gtid_832) * 4] =
            res_891;
    }
}
"""
# Hacky parser/reader for values written in Futhark syntax.  Used for
# reading stdin when compiling standalone programs with the Python
# code generator.

import numpy as np
import string

lookahead_buffer = []

def reset_lookahead():
    global lookahead_buffer
    lookahead_buffer = []

def get_char(f):
    global lookahead_buffer
    if len(lookahead_buffer) == 0:
        return f.read(1)
    else:
        c = lookahead_buffer[0]
        lookahead_buffer = lookahead_buffer[1:]
        return c

def unget_char(f, c):
    global lookahead_buffer
    lookahead_buffer = [c] + lookahead_buffer

def peek_char(f):
    c = get_char(f)
    if c:
        unget_char(f, c)
    return c

def skip_spaces(f):
    c = get_char(f)
    while c != None:
        if c.isspace():
            c = get_char(f)
        elif c == '-':
          # May be line comment.
          if peek_char(f) == '-':
            # Yes, line comment. Skip to end of line.
            while (c != '\n' and c != None):
              c = get_char(f)
          else:
            break
        else:
          break
    if c:
        unget_char(f, c)

def parse_specific_char(f, expected):
    got = get_char(f)
    if got != expected:
        unget_char(f, got)
        raise ValueError
    return True

def parse_specific_string(f, s):
    for c in s:
        parse_specific_char(f, c)
    return True

def optional(p, *args):
    try:
        return p(*args)
    except ValueError:
        return None

def sepBy(p, sep, *args):
    elems = []
    x = optional(p, *args)
    if x != None:
        elems += [x]
        while optional(sep, *args) != None:
            x = p(*args)
            elems += [x]
    return elems

def parse_int(f):
    s = ''
    c = get_char(f)
    if c == '0' and peek_char(f) in ['x', 'X']:
        c = get_char(f) # skip X
        c = get_char(f)
        while c != None:
            if c in string.hexdigits:
                s += c
                c = get_char(f)
            else:
                unget_char(f, c)
                s = str(int(s, 16))
                break
    else:
        while c != None:
            if c.isdigit():
                s += c
                c = get_char(f)
            else:
                unget_char(f, c)
                break
    optional(read_int_trailer, f)
    return s

def parse_int_signed(f):
    s = ''
    c = get_char(f)

    if c == '-' and peek_char(f).isdigit():
      s = c + parse_int(f)
    else:
      if c != '+':
          unget_char(f, c)
      s = parse_int(f)

    return s

def read_int_trailer(f):
  parse_specific_char(f, 'i')
  while peek_char(f).isdigit():
    get_char(f)

def read_comma(f):
    skip_spaces(f)
    parse_specific_char(f, ',')
    return ','

def read_int(f):
    skip_spaces(f)
    return int(parse_int_signed(f))

def read_char(f):
    skip_spaces(f)
    parse_specific_char(f, '\'')
    c = get_char(f)
    parse_specific_char(f, '\'')
    return c

def read_double(f):
    skip_spaces(f)
    c = get_char(f)
    if (c == '-'):
      sign = '-'
    else:
      unget_char(f,c)
      sign = ''
    bef = optional(parse_int, f)
    if bef == None:
        bef = '0'
        parse_specific_char(f, '.')
        aft = parse_int(f)
    elif optional(parse_specific_char, f, '.'):
        aft = parse_int(f)
    else:
        aft = '0'
    if (optional(parse_specific_char, f, 'E') or
        optional(parse_specific_char, f, 'e')):
        expt = parse_int_signed(f)
    else:
        expt = '0'
    optional(read_float_trailer, f)
    return float(sign + bef + '.' + aft + 'E' + expt)

def read_float(f):
    return read_double(f)

def read_float_trailer(f):
  parse_specific_char(f, 'f')
  while peek_char(f).isdigit():
    get_char(f)

def read_bool(f):
    skip_spaces(f)
    if peek_char(f) == 't':
        parse_specific_string(f, 'true')
        return True
    elif peek_char(f) == 'f':
        parse_specific_string(f, 'false')
        return False
    else:
        raise ValueError

def read_empty_array(f, type_name, rank):
    parse_specific_string(f, 'empty')
    parse_specific_char(f, '(')
    for i in range(rank):
        parse_specific_string(f, '[]')
    parse_specific_string(f, type_name)
    parse_specific_char(f, ')')
    return []

def read_array_elems(f, elem_reader, type_name, rank):
    skip_spaces(f)
    try:
        parse_specific_char(f, '[')
    except ValueError:
        return read_empty_array(f, type_name, rank)
    else:
        xs = sepBy(elem_reader, read_comma, f)
        skip_spaces(f)
        parse_specific_char(f, ']')
        return xs

def read_array_helper(f, elem_reader, type_name, rank):
    def nested_row_reader(_):
        return read_array_helper(f, elem_reader, type_name, rank-1)
    if rank == 1:
        row_reader = elem_reader
    else:
        row_reader = nested_row_reader
    return read_array_elems(f, row_reader, type_name, rank-1)

def expected_array_dims(l, rank):
  if rank > 1:
      n = len(l)
      if n == 0:
          elem = []
      else:
          elem = l[0]
      return [n] + expected_array_dims(elem, rank-1)
  else:
      return [len(l)]

def verify_array_dims(l, dims):
    if dims[0] != len(l):
        raise ValueError
    if len(dims) > 1:
        for x in l:
            verify_array_dims(x, dims[1:])

def read_double_signed(f):

    skip_spaces(f)
    c = get_char(f)

    if c == '-' and peek_char(f).isdigit():
      v = -1 * read_double(f)
    else:
      unget_char(f, c)
      v = read_double(f)

    return v

def read_array(f, elem_reader, type_name, rank, bt):
    elems = read_array_helper(f, elem_reader, type_name, rank)
    dims = expected_array_dims(elems, rank)
    verify_array_dims(elems, dims)
    return np.array(elems, dtype=bt)
# Scalar functions.

import numpy as np

def signed(x):
  if type(x) == np.uint8:
    return np.int8(x)
  elif type(x) == np.uint16:
    return np.int16(x)
  elif type(x) == np.uint32:
    return np.int32(x)
  else:
    return np.int64(x)

def unsigned(x):
  if type(x) == np.int8:
    return np.uint8(x)
  elif type(x) == np.int16:
    return np.uint16(x)
  elif type(x) == np.int32:
    return np.uint32(x)
  else:
    return np.uint64(x)

def shlN(x,y):
  return x << y

def ashrN(x,y):
  return x >> y

def sdivN(x,y):
  return x / y

def smodN(x,y):
  return x % y

def udivN(x,y):
  return signed(unsigned(x) / unsigned(y))

def umodN(x,y):
  return signed(unsigned(x) % unsigned(y))

def squotN(x,y):
  return np.int32(float(x) / float(y))

def sremN(x,y):
  return np.fmod(x,y)

def powN(x,y):
  return x ** y

def fpowN(x,y):
  return x ** y

def sleN(x,y):
  return x <= y

def sltN(x,y):
  return x < y

def uleN(x,y):
  return unsigned(x) <= unsigned(y)

def ultN(x,y):
  return unsigned(x) < unsigned(y)

def lshr8(x,y):
  return np.int8(np.uint8(x) >> np.uint8(y))

def lshr16(x,y):
  return np.int16(np.uint16(x) >> np.uint16(y))

def lshr32(x,y):
  return np.int32(np.uint32(x) >> np.uint32(y))

def lshr64(x,y):
  return np.int64(np.uint64(x) >> np.uint64(y))

def sext_T_i8(x):
  return np.int8(x)

def sext_T_i16(x):
  return np.int16(x)

def sext_T_i32(x):
  return np.int32(x)

def sext_T_i64(x):
  return np.int32(x)

def zext_i8_i8(x):
  return np.int8(np.uint8(x))

def zext_i8_i16(x):
  return np.int16(np.uint8(x))

def zext_i8_i32(x):
  return np.int32(np.uint8(x))

def zext_i8_i64(x):
  return np.int64(np.uint8(x))

def zext_i16_i8(x):
  return np.int8(np.uint16(x))

def zext_i16_i16(x):
  return np.int16(np.uint16(x))

def zext_i16_i32(x):
  return np.int32(np.uint16(x))

def zext_i16_i64(x):
  return np.int64(np.uint16(x))

def zext_i32_i8(x):
  return np.int8(np.uint32(x))

def zext_i32_i16(x):
  return np.int16(np.uint32(x))

def zext_i32_i32(x):
  return np.int32(np.uint32(x))

def zext_i32_i64(x):
  return np.int64(np.uint32(x))

def zext_i64_i8(x):
  return np.int8(np.uint64(x))

def zext_i64_i16(x):
  return np.int16(np.uint64(x))

def zext_i64_i32(x):
  return np.int32(np.uint64(x))

def zext_i64_i64(x):
  return np.int64(np.uint64(x))

shl8 = shl16 = shl32 = shl64 = shlN
ashr8 = ashr16 = ashr32 = ashr64 = ashrN
sdiv8 = sdiv16 = sdiv32 = sdiv64 = sdivN
smod8 = smod16 = smod32 = smod64 = smodN
udiv8 = udiv16 = udiv32 = udiv64 = udivN
umod8 = umod16 = umod32 = umod64 = umodN
squot8 = squot16 = squot32 = squot64 = squotN
srem8 = srem16 = srem32 = srem64 = sremN
pow8 = pow16 = pow32 = pow64 = powN
fpow32 = fpow64 = fpowN
sle8 = sle16 = sle32 = sle64 = sleN
slt8 = slt16 = slt32 = slt64 = sltN
ule8 = ule16 = ule32 = ule64 = uleN
ult8 = ult16 = ult32 = ult64 = ultN
sext_i8_i8 = sext_i16_i8 = sext_i32_i8 = sext_i64_i8 = sext_T_i8
sext_i8_i16 = sext_i16_i16 = sext_i32_i16 = sext_i64_i16 = sext_T_i16
sext_i8_i32 = sext_i16_i32 = sext_i32_i32 = sext_i64_i32 = sext_T_i32
sext_i8_i64 = sext_i16_i64 = sext_i32_i64 = sext_i64_i64 = sext_T_i64

def ssignum(x):
  return np.sign(x)

def usignum(x):
  if x < 0:
    return ssignum(-x)
  else:
    return ssignum(x)

def sitofp_T_f32(x):
  return np.float32(x)
sitofp_i8_f32 = sitofp_i16_f32 = sitofp_i32_f32 = sitofp_i64_f32 = sitofp_T_f32

def sitofp_T_f64(x):
  return np.float64(x)
sitofp_i8_f64 = sitofp_i16_f64 = sitofp_i32_f64 = sitofp_i64_f64 = sitofp_T_f64

def uitofp_T_f32(x):
  return np.float32(unsigned(x))
uitofp_i8_f32 = uitofp_i16_f32 = uitofp_i32_f32 = uitofp_i64_f32 = uitofp_T_f32

def uitofp_T_f64(x):
  return np.float64(unsigned(x))
uitofp_i8_f64 = uitofp_i16_f64 = uitofp_i32_f64 = uitofp_i64_f64 = uitofp_T_f64

def fptosi_T_i8(x):
  return np.int8(np.trunc(x))
fptosi_f32_i8 = fptosi_f64_i8 = fptosi_T_i8

def fptosi_T_i16(x):
  return np.int16(np.trunc(x))
fptosi_f32_i16 = fptosi_f64_i16 = fptosi_T_i16

def fptosi_T_i32(x):
  return np.int32(np.trunc(x))
fptosi_f32_i32 = fptosi_f64_i32 = fptosi_T_i32

def fptosi_T_i64(x):
  return np.int64(np.trunc(x))
fptosi_f32_i64 = fptosi_f64_i64 = fptosi_T_i64

def fptoui_T_i8(x):
  return np.uint8(np.trunc(x))
fptoui_f32_i8 = fptoui_f64_i8 = fptoui_T_i8

def fptoui_T_i16(x):
  return np.uint16(np.trunc(x))
fptoui_f32_i16 = fptoui_f64_i16 = fptoui_T_i16

def fptoui_T_i32(x):
  return np.uint32(np.trunc(x))
fptoui_f32_i32 = fptoui_f64_i32 = fptoui_T_i32

def fptoui_T_i64(x):
  return np.uint64(np.trunc(x))
fptoui_f32_i64 = fptoui_f64_i64 = fptoui_T_i64

def fpconv_f32_f64(x):
  return np.float64(x)

def fpconv_f64_f32(x):
  return np.float32(x)

def futhark_log64(x):
  return np.float64(np.log(x))

def futhark_sqrt64(x):
  return np.sqrt(x)

def futhark_exp64(x):
  return np.exp(x)

def futhark_cos64(x):
  return np.cos(x)

def futhark_sin64(x):
  return np.sin(x)

def futhark_acos64(x):
  return np.arccos(x)

def futhark_asin64(x):
  return np.arcsin(x)

def futhark_atan64(x):
  return np.arctan(x)

def futhark_atan2_64(x, y):
  return np.arctan2(x, y)

def futhark_isnan64(x):
  return np.isnan(x)

def futhark_isinf64(x):
  return np.isinf(x)

def futhark_log32(x):
  return np.float32(np.log(x))

def futhark_sqrt32(x):
  return np.float32(np.sqrt(x))

def futhark_exp32(x):
  return np.exp(x)

def futhark_cos32(x):
  return np.cos(x)

def futhark_sin32(x):
  return np.sin(x)

def futhark_acos32(x):
  return np.arccos(x)

def futhark_asin32(x):
  return np.arcsin(x)

def futhark_atan32(x):
  return np.arctan(x)

def futhark_atan2_32(x, y):
  return np.arctan2(x, y)

def futhark_isnan32(x):
  return np.isnan(x)

def futhark_isinf32(x):
  return np.isinf(x)
class visualise_model:
  def __init__(self, interactive=False, platform_pref=preferred_platform,
               device_pref=preferred_device, group_size=256, num_groups=128,
               tile_size=32):
    self.ctx = get_prefered_context(interactive, platform_pref, device_pref)
    self.queue = cl.CommandQueue(self.ctx)
    self.device = self.ctx.get_info(cl.context_info.DEVICES)[0]
     # XXX: Assuming just a single device here.
    platform_name = self.ctx.get_info(cl.context_info.DEVICES)[0].platform.name
    device_type = self.device.type
    lockstep_width = 1
    if ((platform_name == "NVIDIA CUDA") and (device_type == cl.device_type.GPU)):
      lockstep_width = np.int32(32)
    if ((platform_name == "AMD Accelerated Parallel Processing") and (device_type == cl.device_type.GPU)):
      lockstep_width = np.int32(64)
    max_tile_size = int(np.sqrt(self.device.max_work_group_size))
    if (tile_size * tile_size > self.device.max_work_group_size):
      sys.stderr.write('Warning: Device limits tile size to {} (setting was {})\n'.format(max_tile_size, tile_size))
      tile_size = max_tile_size
    self.group_size = group_size
    self.num_groups = num_groups
    self.tile_size = tile_size
    if (len(fut_opencl_src) >= 0):
      program = cl.Program(self.ctx, fut_opencl_src).build(["-DFUT_BLOCK_DIM={}".format(FUT_BLOCK_DIM),
                                                            "-DLOCKSTEP_WIDTH={}".format(lockstep_width),
                                                            "-DDEFAULT_GROUP_SIZE={}".format(group_size),
                                                            "-DDEFAULT_NUM_GROUPS={}".format(num_groups),
                                                            "-DDEFAULT_TILE_SIZE={}".format(tile_size)])
    
    self.map_kernel_898_var = program.map_kernel_898
    self.map_kernel_839_var = program.map_kernel_839
  def futhark_advance(self, s_740, _setting_741):
    res_742 = (s_740 + np.float32((1.0e-2)))
    scalar_out_916 = res_742
    return scalar_out_916
  def futhark_render(self, width_743, height_744, time_745, degree_746):
    y_749 = sitofp_i32_f32(height_744)
    y_750 = sitofp_i32_f32(width_743)
    x_751 = fpow32(time_745, np.float32((1.5)))
    y_752 = (x_751 * np.float32((5.0e-3)))
    res_753 = (np.float32((1.0)) + y_752)
    res_754 = (np.float32((3.1415927)) / res_753)
    group_size_893 = self.group_size
    y_894 = (group_size_893 - np.int32(1))
    x_895 = (width_743 + y_894)
    num_groups_896 = squot32(x_895, group_size_893)
    num_threads_897 = (num_groups_896 * group_size_893)
    bytes_911 = (np.int32(4) * width_743)
    mem_912 = cl.Buffer(self.ctx, cl.mem_flags.READ_WRITE,
                        np.long(np.long(bytes_911) if (bytes_911 > np.int32(0)) else np.int32(1)))
    if ((np.int32(1) * (num_groups_896 * group_size_893)) != np.int32(0)):
      self.map_kernel_898_var.set_args(mem_912, np.float32(y_749),
                                       np.int32(width_743))
      cl.enqueue_nd_range_kernel(self.queue, self.map_kernel_898_var,
                                 (np.long((num_groups_896 * group_size_893)),),
                                 (np.long(group_size_893),))
      if synchronous:
        self.queue.finish()
    nesting_size_833 = (height_744 * width_743)
    x_836 = (nesting_size_833 + y_894)
    num_groups_837 = squot32(x_836, group_size_893)
    num_threads_838 = (num_groups_837 * group_size_893)
    bytes_913 = (bytes_911 * height_744)
    mem_915 = cl.Buffer(self.ctx, cl.mem_flags.READ_WRITE,
                        np.long(np.long(bytes_913) if (bytes_913 > np.int32(0)) else np.int32(1)))
    if ((np.int32(1) * (num_groups_837 * group_size_893)) != np.int32(0)):
      self.map_kernel_839_var.set_args(mem_912, np.int32(height_744),
                                       np.float32(res_754), np.float32(y_750),
                                       np.int32(degree_746), mem_915,
                                       np.int32(width_743))
      cl.enqueue_nd_range_kernel(self.queue, self.map_kernel_839_var,
                                 (np.long((num_groups_837 * group_size_893)),),
                                 (np.long(group_size_893),))
      if synchronous:
        self.queue.finish()
    out_mem_917 = mem_915
    out_memsize_918 = bytes_913
    return (out_memsize_918, out_mem_917)
  def futhark_initial_state(self):
    scalar_out_925 = np.float32((0.0))
    return scalar_out_925
  def advance(self, s_740_ext, _setting_741_ext):
    s_740 = np.float32(s_740_ext)
    _setting_741 = np.int32(_setting_741_ext)
    scalar_out_916 = self.futhark_advance(s_740, _setting_741)
    return scalar_out_916
  def render(self, width_743_ext, height_744_ext, time_745_ext, degree_746_ext):
    width_743 = np.int32(width_743_ext)
    height_744 = np.int32(height_744_ext)
    time_745 = np.float32(time_745_ext)
    degree_746 = np.int32(degree_746_ext)
    (out_memsize_918, out_mem_917) = self.futhark_render(width_743, height_744,
                                                         time_745, degree_746)
    return cl.array.Array(self.queue, (width_743, height_744), ct.c_int32,
                          data=out_mem_917)
  def initial_state(self):
    scalar_out_925 = self.futhark_initial_state()
    return scalar_out_925