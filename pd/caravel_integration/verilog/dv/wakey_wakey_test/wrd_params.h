// Generated by numpy_arch
const int conv1_filter_width = 3;
const int conv1_n_filters = 8;
// CFG reg order: {data3, data2, data1, data0}
const int conv1_weights[3][8][4] = {
{{0x38, 0xfb1d4735, 0xdc0b2224, 0x30d7eafd},
{0x8f, 0xd7f7fc16, 0x226ad2f, 0x121e1932},
{0xd9, 0xfb121119, 0xe25d640a, 0xf41f0a4d},
{0xb, 0xeb0ff7fd, 0xef12f5f1, 0x1f1e0103},
{0xd0, 0x1005d8de, 0xe92adcfd, 0x8110238},
{0xc4, 0x1a3e0bb9, 0xca172623, 0x25e04028},
{0x34, 0x509fa1c, 0xfab6c5a5, 0xe9e421e0},
{0xd4, 0xcf1ffacd, 0xf07f2026, 0xf316db4f}},
{{0xeb, 0x6dd0eed, 0xbf1f370b, 0x14f0b228},
{0x13, 0x24f5eef1, 0x3cd10aef, 0xd20f01d},
{0x11, 0xf7102cee, 0xffdbe304, 0x5dfacdd},
{0xfa, 0xd102f3d1, 0xd90926f6, 0xf524e1e4},
{0xe8, 0xd8584602, 0xea402502, 0xf8170304},
{0xf4, 0x3b3cd1be, 0x101ef8dd, 0xcddd1ce6},
{0xeb, 0x2aefdadb, 0x57cd16cc, 0xfca733d8},
{0xe7, 0xf41d68e5, 0xeb384716, 0x10160123}},
{{0xcb, 0x1d4818c9, 0xef773bdc, 0xa4251e25},
{0x13, 0xcedfbbcf, 0xbbcf05f6, 0xeb06e11d},
{0x1e, 0x17f02457, 0x13e9ec2b, 0xcf18abcd},
{0xf1, 0xe415c6cc, 0xaf9f7d9, 0x429ebfd},
{0xe5, 0xfb016838, 0xdbff4813, 0x20cec0d},
{0x37, 0xdc9bbfdd, 0x1302f4d3, 0xb0d6121c},
{0xb8, 0xbbdaddb4, 0xf8f530fe, 0x122e22d8},
{0x8, 0x18db4418, 0xfcfb2232, 0x2410d414}}};

// Conv biases should each be written to the CFG data0 reg.
const int conv1_biases[8] = {
0xffffffcd, 
0xffffffe6, 
0xfffffffe, 
0xffffffb1, 
0xffffffe9, 
0xffffffd7, 
0xffffffb6, 
0xffffffd6};

const int conv1_shift = 0x6;

const int conv2_filter_width = 3;
const int conv2_n_filters = 16;
// CFG reg order: {data3, data2, data1, data0}
const int conv2_weights[3][16][4] = {
{{0x0, 0x0, 0x1cdedadf, 0x1d013ef},
{0x0, 0x0, 0x24f9ef08, 0xd9f723f9},
{0x0, 0x0, 0xca1dfb16, 0xf3fad6f9},
{0x0, 0x0, 0x242ff2d4, 0xeb07eff0},
{0x0, 0x0, 0xfff334c2, 0x16ee05f0},
{0x0, 0x0, 0x6fe00f9, 0xe62cd4eb},
{0x0, 0x0, 0xb929fb06, 0xe9b8dbeb},
{0x0, 0x0, 0xd102d7e4, 0x4a01dfdd},
{0x0, 0x0, 0xe6f1f7f6, 0xf4f00ded},
{0x0, 0x0, 0xed17f709, 0xbaa500bd},
{0x0, 0x0, 0xdffd00bf, 0x34fde928},
{0x0, 0x0, 0xfb2df8e3, 0xfee4c4f7},
{0x0, 0x0, 0xf1f1f4cf, 0xffffeb4f},
{0x0, 0x0, 0x1707c123, 0xd2f0e50c},
{0x0, 0x0, 0xf92bbd24, 0xe8fc1025},
{0x0, 0x0, 0x8e1d51e, 0xf6f7e6f8}},
{{0x0, 0x0, 0xfeeec42c, 0xeee08f6},
{0x0, 0x0, 0x814a902, 0xe505fcef},
{0x0, 0x0, 0xcd1900e4, 0xfbf9c303},
{0x0, 0x0, 0xefc0f2c9, 0xef2fe8f3},
{0x0, 0x0, 0xfcf9d7db, 0x2ffc06f2},
{0x0, 0x0, 0x2667fe07, 0xecfeedf1},
{0x0, 0x0, 0x1ce909fa, 0xe741dff6},
{0x0, 0x0, 0xe2e701ce, 0x34f5d1f5},
{0x0, 0x0, 0xc200043d, 0xe80e0b07},
{0x0, 0x0, 0x24317f9, 0xd2c9fae6},
{0x0, 0x0, 0xddea09be, 0x3df8edbb},
{0x0, 0x0, 0x3b40f9f8, 0xfcf9d604},
{0x0, 0x0, 0xe4e1fdca, 0x66edcede},
{0x0, 0x0, 0xf313a7d8, 0xe8ff140a},
{0x0, 0x0, 0x2e8a3e9, 0xc05f715},
{0x0, 0x0, 0xfae10127, 0xd60aff03}},
{{0x0, 0x0, 0xde04d118, 0xf4e616ef},
{0x0, 0x0, 0xd60cbd02, 0x7f8e1c9},
{0x0, 0x0, 0xc8f7022d, 0xe8fedcf8},
{0x0, 0x0, 0x342df501, 0xf802fb02},
{0x0, 0x0, 0xe1fad127, 0xcdfc04e8},
{0x0, 0x0, 0x2f7ff03, 0xe7b6f7f6},
{0x0, 0x0, 0x34afe01, 0xdbdbe7ee},
{0x0, 0x0, 0xe4c917bd, 0xbf2d239},
{0x0, 0x0, 0xe2eb00f5, 0xf002f308},
{0x0, 0x0, 0x1d0204f8, 0xd939eddb},
{0x0, 0x0, 0xdccc05f3, 0xd8fa244f},
{0x0, 0x0, 0x619f516, 0xe526e0f0},
{0x0, 0x0, 0xfbcf11bf, 0xf0dc0313},
{0x0, 0x0, 0xdcdca7d4, 0xdff1f6e5},
{0x0, 0x0, 0xf1f181f6, 0x4020a1f},
{0x0, 0x0, 0x4defdf3, 0xfddcdaf3}}};

// Conv biases should each be written to the CFG data0 reg.
const int conv2_biases[16] = {
0xfffffefa, 
0x17, 
0x88, 
0xfffffee3, 
0xffffff17, 
0x9f, 
0xae, 
0x1e, 
0xfffffed8, 
0x2e, 
0xffffff3f, 
0xffffffad, 
0xffffff47, 
0xab, 
0xfffffffd, 
0x1e};

const int conv2_shift = 0x6;

const int fc_n_classes = 2;
const int fc_in_length = 208;
const int fc_weights[2][208] = {
{0xffffffc6,
0xffffffe1,
0x8,
0x16,
0x1a,
0x2c,
0x18,
0x9,
0x12,
0x13,
0x2f,
0x3b,
0x4d,
0xffffffdc,
0x19,
0x2f,
0xfffffff3,
0xfffffff5,
0x3d,
0x2c,
0x1b,
0x2c,
0x1a,
0x19,
0xffffffeb,
0x28,
0xffffffe5,
0xffffff97,
0xffffffb3,
0xffffffdf,
0xfffffff8,
0xfffffff2,
0xfffffffb,
0xfffffff6,
0xffffffe5,
0xffffffe8,
0xe,
0xfffffff6,
0x16,
0xfffffff4,
0xfffffff4,
0xffffffdd,
0xffffffe9,
0xffffffd5,
0xffffffef,
0xffffffd3,
0xffffffb7,
0xffffffdd,
0xffffffd4,
0x6,
0xd,
0x11,
0xffffffba,
0x22,
0x41,
0x9,
0x1e,
0x1e,
0x29,
0x24,
0x3e,
0x2,
0x2b,
0x20,
0xfffffff9,
0xfffffffc,
0xffffffff,
0x5,
0xffffffdb,
0xffffffd9,
0xfffffff8,
0xfffffffe,
0xffffffe0,
0xffffffe2,
0xffffffff,
0xffffffcc,
0xffffffe7,
0x0,
0xffffffef,
0xffffffed,
0xffffffe5,
0xffffffe2,
0xffffffdb,
0xffffffed,
0xffffffde,
0xffffffcd,
0xfffffffa,
0xfffffff7,
0xffffffc4,
0xfffffff4,
0x9,
0x37,
0xd,
0x29,
0x17,
0x16,
0xf,
0x1b,
0x2c,
0x38,
0x31,
0x6c,
0x32,
0x1,
0xffffffa9,
0xffffffba,
0xffffffe3,
0xfffffff2,
0xfffffff7,
0x10,
0xfffffffe,
0x7,
0xfffffff9,
0x1e,
0xa,
0x33,
0x3f,
0xfffffff1,
0xfffffff8,
0xfffffffa,
0xffffffd6,
0xffffffdc,
0xffffffdb,
0xffffffea,
0xffffffcd,
0xffffffcd,
0xffffffec,
0xffffffad,
0xffffffdd,
0xffffffd9,
0x42,
0x42,
0x28,
0x13,
0x10,
0x32,
0x1b,
0x1a,
0x3c,
0x2f,
0x4a,
0xffffffef,
0x18,
0xfffffff6,
0xffffffdc,
0xffffffe8,
0xffffffce,
0xffffffca,
0xffffffdf,
0xffffffe2,
0xffffffce,
0x11,
0xffffffee,
0xffffffdf,
0xfffffff6,
0xa,
0x5e,
0x39,
0x36,
0x29,
0x24,
0x39,
0x1d,
0x2b,
0xffffffff,
0x1b,
0x5c,
0x4d,
0x0,
0xfffffff3,
0xfffffff3,
0xffffffe9,
0xffffffff,
0x15,
0x22,
0x3c,
0x48,
0x49,
0x34,
0x5b,
0x27,
0x41,
0x38,
0x13,
0x16,
0x15,
0x1c,
0x35,
0x38,
0x1c,
0x20,
0x16,
0x25,
0xe,
0x14,
0xffffffc1,
0xffffffd8,
0xffffffc8,
0xfffffff1,
0xfffffffc,
0xfffffffa,
0x3,
0x7,
0x12,
0x16,
0x10,
0x1e,
0x1b},
{0x3d,
0x31,
0xb,
0xffffffef,
0xffffffed,
0xffffffef,
0xffffffe7,
0xffffffe5,
0xffffffec,
0xffffffd9,
0xffffffe7,
0xffffffef,
0xffffffb5,
0x2d,
0xfffffff1,
0xffffffef,
0xb,
0x5,
0xffffffcd,
0xffffffdf,
0x4,
0xffffffdd,
0xffffffe2,
0xffffffcd,
0xd,
0xffffffd3,
0x40,
0x50,
0x39,
0x13,
0x2e,
0x9,
0xe,
0xffffffeb,
0x8,
0x3,
0xfffffffe,
0xc,
0xfffffff9,
0x2,
0x15,
0x38,
0x1c,
0x35,
0x1c,
0x4b,
0x39,
0x2f,
0x20,
0xffffffe1,
0x6,
0xfffffff6,
0x3c,
0xffffffce,
0xffffffcb,
0xffffffec,
0xffffffc6,
0xffffffd7,
0xffffffb8,
0xffffffd7,
0xffffffde,
0xffffffef,
0xffffffe0,
0xffffffd9,
0xffffffef,
0xd,
0x11,
0x14,
0x11,
0x1e,
0x11,
0x10,
0x0,
0x12,
0x13,
0x39,
0x1,
0xa,
0x1,
0x2,
0xc,
0x31,
0x27,
0x7,
0x14,
0x2d,
0x1d,
0x15,
0x3e,
0x1f,
0xffffffee,
0xffffffc6,
0xffffffdf,
0xfffffff1,
0xfffffff0,
0xffffffde,
0xffffffd7,
0xffffffe7,
0xffffffce,
0xffffffcf,
0xffffffd5,
0xffffff81,
0xffffffd1,
0xfffffffe,
0x45,
0x3e,
0x30,
0xf,
0xe,
0x5,
0xffffffe1,
0xffffffda,
0xfffffff9,
0xfffffffb,
0xffffffeb,
0xffffffd8,
0xffffffc2,
0xd,
0xc,
0x26,
0x2f,
0x33,
0x17,
0x19,
0x21,
0x27,
0x1d,
0x3f,
0x1c,
0x19,
0xffffffca,
0xffffffe0,
0xfffffff2,
0xffffffcc,
0xffffffde,
0xffffffcc,
0xffffffeb,
0xfffffff3,
0xffffffcc,
0xffffffea,
0xffffffae,
0xfffffff7,
0xffffffeb,
0x5,
0xd,
0x23,
0x32,
0x15,
0x1e,
0x21,
0xb,
0x15,
0x32,
0x2d,
0xfffffff2,
0xe,
0xffffffc5,
0xffffffd5,
0xffffffc8,
0xffffffea,
0xffffffe6,
0xffffffd5,
0xffffffef,
0xffffffea,
0x3,
0xffffffda,
0xffffffc6,
0xffffff91,
0xa,
0xc,
0x24,
0x28,
0xffffffed,
0xfffffffb,
0xffffffc9,
0xffffffca,
0xffffffc8,
0xffffffc8,
0xffffffcb,
0xffffffb3,
0xffffffc0,
0xffffffd3,
0xffffffdc,
0x1,
0x2,
0xffffffee,
0xffffffd6,
0xffffffc8,
0xffffffc9,
0xffffffce,
0xffffffe1,
0xffffffd9,
0xffffffd2,
0xffffffed,
0xffffffd4,
0x2b,
0x21,
0x3c,
0x11,
0xfffffffa,
0xfffffff8,
0xfffffff9,
0xffffffed,
0xffffffec,
0xfffffffd,
0xfffffff2,
0x6,
0xffffffea}};

const int fc_biases[2] = {
0xfffffbbc, 
0x3a8};

