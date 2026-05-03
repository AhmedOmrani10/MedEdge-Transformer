library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.transformer_pkg.all;

entity feed_forward is
    port (
        clk   : in  std_logic;
        rst   : in  std_logic;
        start : in  std_logic;
        X_in  : in  matrix_16x16;
        Y_out : out matrix_16x16;
        done  : out std_logic
    );
end feed_forward;

architecture Behavioral of feed_forward is

    type weight_32x16 is array(0 to 511) of signed(15 downto 0);
    type weight_16x32 is array(0 to 511) of signed(15 downto 0);
    type bias_32      is array(0 to 31)  of signed(15 downto 0);
    type bias_16      is array(0 to 15)  of signed(15 downto 0);

    constant FF1_W : weight_32x16 := (
        to_signed(4154,16), to_signed(4610,16), to_signed(-3441,16), to_signed(4263,16), to_signed(9835,16), to_signed(-2991,16), to_signed(8758,16), to_signed(-9950,16),
        to_signed(412,16), to_signed(3440,16), to_signed(-3403,16), to_signed(-630,16), to_signed(-7591,16), to_signed(-9835,16), to_signed(3205,16), to_signed(-2231,16),
        to_signed(2427,16), to_signed(409,16), to_signed(1016,16), to_signed(2197,16), to_signed(11469,16), to_signed(907,16), to_signed(81,16), to_signed(-2418,16),
        to_signed(971,16), to_signed(1018,16), to_signed(-4309,16), to_signed(-4127,16), to_signed(1326,16), to_signed(-4098,16), to_signed(-541,16), to_signed(-1375,16),
        to_signed(-70,16), to_signed(967,16), to_signed(517,16), to_signed(-1621,16), to_signed(-723,16), to_signed(4783,16), to_signed(-645,16), to_signed(-8720,16),
        to_signed(4202,16), to_signed(6113,16), to_signed(-5816,16), to_signed(541,16), to_signed(1192,16), to_signed(3904,16), to_signed(1176,16), to_signed(1718,16),
        to_signed(7467,16), to_signed(6379,16), to_signed(-2104,16), to_signed(5082,16), to_signed(7961,16), to_signed(-32,16), to_signed(-11357,16), to_signed(-1635,16),
        to_signed(-3165,16), to_signed(-2236,16), to_signed(1343,16), to_signed(-2047,16), to_signed(3443,16), to_signed(-9639,16), to_signed(7706,16), to_signed(3514,16),
        to_signed(1390,16), to_signed(-7798,16), to_signed(-1798,16), to_signed(2005,16), to_signed(6042,16), to_signed(-7028,16), to_signed(1214,16), to_signed(9044,16),
        to_signed(-3420,16), to_signed(-160,16), to_signed(1501,16), to_signed(125,16), to_signed(894,16), to_signed(-4474,16), to_signed(2149,16), to_signed(1420,16),
        to_signed(7799,16), to_signed(-1478,16), to_signed(-858,16), to_signed(377,16), to_signed(-1818,16), to_signed(-10988,16), to_signed(473,16), to_signed(6002,16),
        to_signed(-8798,16), to_signed(-8782,16), to_signed(-3699,16), to_signed(-665,16), to_signed(-2600,16), to_signed(4010,16), to_signed(4401,16), to_signed(1373,16),
        to_signed(-2746,16), to_signed(6179,16), to_signed(3667,16), to_signed(3586,16), to_signed(4468,16), to_signed(-11449,16), to_signed(11469,16), to_signed(5855,16),
        to_signed(-4554,16), to_signed(-3100,16), to_signed(831,16), to_signed(-4615,16), to_signed(-6925,16), to_signed(2521,16), to_signed(-1135,16), to_signed(-7413,16),
        to_signed(3390,16), to_signed(5123,16), to_signed(-4432,16), to_signed(5778,16), to_signed(8331,16), to_signed(3026,16), to_signed(1766,16), to_signed(-7836,16),
        to_signed(-1875,16), to_signed(-262,16), to_signed(-2343,16), to_signed(-1582,16), to_signed(-1427,16), to_signed(-70,16), to_signed(588,16), to_signed(-683,16),
        to_signed(1730,16), to_signed(1099,16), to_signed(-3592,16), to_signed(6909,16), to_signed(657,16), to_signed(-2991,16), to_signed(-4373,16), to_signed(2937,16),
        to_signed(-5593,16), to_signed(-180,16), to_signed(4013,16), to_signed(-366,16), to_signed(-342,16), to_signed(-7075,16), to_signed(7368,16), to_signed(519,16),
        to_signed(11469,16), to_signed(-5056,16), to_signed(9064,16), to_signed(-3047,16), to_signed(-6226,16), to_signed(-2765,16), to_signed(11469,16), to_signed(10771,16),
        to_signed(-3521,16), to_signed(-5026,16), to_signed(1231,16), to_signed(-2035,16), to_signed(137,16), to_signed(-6118,16), to_signed(2035,16), to_signed(1464,16),
        to_signed(3322,16), to_signed(-8254,16), to_signed(-1979,16), to_signed(6865,16), to_signed(-5628,16), to_signed(-2337,16), to_signed(-4194,16), to_signed(-1268,16),
        to_signed(-7155,16), to_signed(-949,16), to_signed(11469,16), to_signed(842,16), to_signed(273,16), to_signed(-10015,16), to_signed(7855,16), to_signed(1035,16),
        to_signed(-178,16), to_signed(6613,16), to_signed(-11469,16), to_signed(6723,16), to_signed(2157,16), to_signed(-3428,16), to_signed(1487,16), to_signed(-4732,16),
        to_signed(-8683,16), to_signed(-5736,16), to_signed(6998,16), to_signed(-4337,16), to_signed(-1419,16), to_signed(2022,16), to_signed(7254,16), to_signed(946,16),
        to_signed(-889,16), to_signed(-4217,16), to_signed(-3604,16), to_signed(6591,16), to_signed(9764,16), to_signed(-7375,16), to_signed(-6991,16), to_signed(1376,16),
        to_signed(-4707,16), to_signed(-2498,16), to_signed(6499,16), to_signed(-2380,16), to_signed(-194,16), to_signed(-2348,16), to_signed(2653,16), to_signed(-1504,16),
        to_signed(101,16), to_signed(-2265,16), to_signed(1733,16), to_signed(1290,16), to_signed(-998,16), to_signed(3759,16), to_signed(1862,16), to_signed(-8738,16),
        to_signed(2113,16), to_signed(2040,16), to_signed(-954,16), to_signed(1124,16), to_signed(-1633,16), to_signed(1609,16), to_signed(-461,16), to_signed(-1014,16),
        to_signed(-6710,16), to_signed(6249,16), to_signed(11442,16), to_signed(-6689,16), to_signed(-813,16), to_signed(-10787,16), to_signed(11100,16), to_signed(1092,16),
        to_signed(2949,16), to_signed(-3389,16), to_signed(-4134,16), to_signed(-4623,16), to_signed(-2851,16), to_signed(11469,16), to_signed(-11469,16), to_signed(-5774,16),
        to_signed(-1451,16), to_signed(-11469,16), to_signed(6157,16), to_signed(6602,16), to_signed(11469,16), to_signed(-7670,16), to_signed(3031,16), to_signed(-8814,16),
        to_signed(-1885,16), to_signed(-696,16), to_signed(11469,16), to_signed(-1121,16), to_signed(-908,16), to_signed(-4711,16), to_signed(-1145,16), to_signed(-1758,16),
        to_signed(-963,16), to_signed(4031,16), to_signed(6736,16), to_signed(11469,16), to_signed(-487,16), to_signed(-772,16), to_signed(1295,16), to_signed(1936,16),
        to_signed(-2789,16), to_signed(971,16), to_signed(589,16), to_signed(-4270,16), to_signed(-11122,16), to_signed(8344,16), to_signed(-1146,16), to_signed(-11268,16),
        to_signed(-130,16), to_signed(3217,16), to_signed(-360,16), to_signed(810,16), to_signed(5246,16), to_signed(1393,16), to_signed(3169,16), to_signed(11469,16),
        to_signed(2901,16), to_signed(-2638,16), to_signed(-4454,16), to_signed(-5030,16), to_signed(3108,16), to_signed(4138,16), to_signed(-6317,16), to_signed(-856,16),
        to_signed(557,16), to_signed(6327,16), to_signed(3615,16), to_signed(-2465,16), to_signed(2296,16), to_signed(6338,16), to_signed(-3213,16), to_signed(-5598,16),
        to_signed(2231,16), to_signed(1301,16), to_signed(-9018,16), to_signed(1004,16), to_signed(-411,16), to_signed(2448,16), to_signed(-6669,16), to_signed(937,16),
        to_signed(2365,16), to_signed(-11469,16), to_signed(-1038,16), to_signed(8840,16), to_signed(6038,16), to_signed(-11339,16), to_signed(-8100,16), to_signed(4442,16),
        to_signed(-7982,16), to_signed(-1865,16), to_signed(11469,16), to_signed(-169,16), to_signed(3092,16), to_signed(-7787,16), to_signed(3515,16), to_signed(1637,16),
        to_signed(5536,16), to_signed(-1147,16), to_signed(927,16), to_signed(8214,16), to_signed(4066,16), to_signed(-1907,16), to_signed(-1419,16), to_signed(1997,16),
        to_signed(-3909,16), to_signed(231,16), to_signed(5143,16), to_signed(-915,16), to_signed(-2081,16), to_signed(-9984,16), to_signed(8725,16), to_signed(-166,16),
        to_signed(-2521,16), to_signed(-2424,16), to_signed(-4964,16), to_signed(985,16), to_signed(2509,16), to_signed(2566,16), to_signed(-9374,16), to_signed(11469,16),
        to_signed(3522,16), to_signed(-2895,16), to_signed(3820,16), to_signed(-2125,16), to_signed(-2150,16), to_signed(-1716,16), to_signed(-1651,16), to_signed(5064,16),
        to_signed(-2800,16), to_signed(-6710,16), to_signed(-6972,16), to_signed(-2000,16), to_signed(4895,16), to_signed(-3011,16), to_signed(8407,16), to_signed(3542,16),
        to_signed(812,16), to_signed(-2489,16), to_signed(8925,16), to_signed(575,16), to_signed(4376,16), to_signed(-587,16), to_signed(-1815,16), to_signed(3773,16),
        to_signed(-3927,16), to_signed(8470,16), to_signed(-759,16), to_signed(3424,16), to_signed(7995,16), to_signed(5044,16), to_signed(-4827,16), to_signed(1036,16),
        to_signed(-1984,16), to_signed(682,16), to_signed(-2719,16), to_signed(-4776,16), to_signed(-4369,16), to_signed(-1091,16), to_signed(763,16), to_signed(-5055,16),
        to_signed(155,16), to_signed(-3359,16), to_signed(-504,16), to_signed(5246,16), to_signed(1951,16), to_signed(-1618,16), to_signed(18,16), to_signed(6032,16),
        to_signed(-3335,16), to_signed(544,16), to_signed(5272,16), to_signed(-635,16), to_signed(-480,16), to_signed(-8159,16), to_signed(2124,16), to_signed(144,16),
        to_signed(5481,16), to_signed(-11280,16), to_signed(6451,16), to_signed(8505,16), to_signed(6550,16), to_signed(2832,16), to_signed(-2373,16), to_signed(-10374,16),
        to_signed(1875,16), to_signed(1092,16), to_signed(10400,16), to_signed(2040,16), to_signed(2009,16), to_signed(-11235,16), to_signed(3917,16), to_signed(1847,16),
        to_signed(1151,16), to_signed(-409,16), to_signed(2249,16), to_signed(-299,16), to_signed(3633,16), to_signed(-2946,16), to_signed(3215,16), to_signed(-730,16),
        to_signed(-870,16), to_signed(-103,16), to_signed(-5884,16), to_signed(-1356,16), to_signed(-2559,16), to_signed(-2558,16), to_signed(-2199,16), to_signed(-2962,16),
        to_signed(-872,16), to_signed(11469,16), to_signed(1697,16), to_signed(7479,16), to_signed(-1724,16), to_signed(-11469,16), to_signed(8617,16), to_signed(4914,16),
        to_signed(-7719,16), to_signed(-1236,16), to_signed(-1941,16), to_signed(-488,16), to_signed(-7792,16), to_signed(6767,16), to_signed(1149,16), to_signed(-5927,16),
        to_signed(-6537,16), to_signed(-5652,16), to_signed(1854,16), to_signed(-3419,16), to_signed(1363,16), to_signed(-3103,16), to_signed(11469,16), to_signed(8245,16),
        to_signed(-3146,16), to_signed(1933,16), to_signed(-748,16), to_signed(-415,16), to_signed(-219,16), to_signed(-5049,16), to_signed(-4159,16), to_signed(30,16),
        to_signed(9622,16), to_signed(5257,16), to_signed(11163,16), to_signed(9123,16), to_signed(-2076,16), to_signed(-11469,16), to_signed(-3366,16), to_signed(1503,16),
        to_signed(-11469,16), to_signed(-2537,16), to_signed(11469,16), to_signed(5441,16), to_signed(4240,16), to_signed(-6206,16), to_signed(11469,16), to_signed(2726,16),
        to_signed(-1242,16), to_signed(1682,16), to_signed(-11469,16), to_signed(4100,16), to_signed(3211,16), to_signed(-5274,16), to_signed(128,16), to_signed(-1591,16),
        to_signed(-5418,16), to_signed(-5228,16), to_signed(9160,16), to_signed(-2646,16), to_signed(-114,16), to_signed(6737,16), to_signed(3788,16), to_signed(824,16),
        to_signed(-5509,16), to_signed(7736,16), to_signed(-11469,16), to_signed(494,16), to_signed(1159,16), to_signed(-4581,16), to_signed(2364,16), to_signed(4731,16),
        to_signed(-628,16), to_signed(-8957,16), to_signed(-2616,16), to_signed(-1807,16), to_signed(348,16), to_signed(-1257,16), to_signed(354,16), to_signed(1928,16)
    );

    constant FF1_B : bias_32 := (
        to_signed(-3455,16), to_signed(1976,16), to_signed(-2887,16), to_signed(7002,16),
        to_signed(-1634,16), to_signed(8354,16), to_signed(-3607,16), to_signed(3651,16),
        to_signed(-3746,16), to_signed(3327,16), to_signed(64,16),    to_signed(4086,16),
        to_signed(7443,16),  to_signed(-508,16),  to_signed(3053,16),  to_signed(-6869,16),
        to_signed(1511,16),  to_signed(937,16),   to_signed(-739,16),  to_signed(-1798,16),
        to_signed(-159,16),  to_signed(430,16),   to_signed(543,16),   to_signed(-413,16),
        to_signed(-1451,16), to_signed(-4572,16), to_signed(-1957,16), to_signed(-11133,16),
        to_signed(-639,16),  to_signed(-11469,16),to_signed(3910,16),  to_signed(251,16)
    );

    constant FF2_W : weight_16x32 := (
        to_signed(-7569,16), to_signed(-4370,16), to_signed(-6067,16), to_signed(1918,16), to_signed(-8192,16), to_signed(7408,16), to_signed(295,16), to_signed(-3444,16),
        to_signed(6879,16), to_signed(-3853,16), to_signed(6883,16), to_signed(8192,16), to_signed(7593,16), to_signed(735,16), to_signed(-1121,16), to_signed(7076,16),
        to_signed(-8192,16), to_signed(-3029,16), to_signed(-4041,16), to_signed(5066,16), to_signed(7694,16), to_signed(6812,16), to_signed(4846,16), to_signed(3941,16),
        to_signed(5649,16), to_signed(4503,16), to_signed(-779,16), to_signed(695,16), to_signed(6916,16), to_signed(-8192,16), to_signed(6183,16), to_signed(4646,16),
        to_signed(7255,16), to_signed(4286,16), to_signed(5721,16), to_signed(-3790,16), to_signed(8192,16), to_signed(-7452,16), to_signed(488,16), to_signed(2356,16),
        to_signed(-5028,16), to_signed(2952,16), to_signed(-5966,16), to_signed(-8192,16), to_signed(-8192,16), to_signed(187,16), to_signed(856,16), to_signed(-8192,16),
        to_signed(8192,16), to_signed(3525,16), to_signed(4758,16), to_signed(-8047,16), to_signed(-8192,16), to_signed(-6773,16), to_signed(-7914,16), to_signed(-955,16),
        to_signed(-7711,16), to_signed(1627,16), to_signed(-3,16), to_signed(2858,16), to_signed(-8192,16), to_signed(8192,16), to_signed(-7975,16), to_signed(-4061,16),
        to_signed(5631,16), to_signed(6342,16), to_signed(3278,16), to_signed(-4537,16), to_signed(8192,16), to_signed(-7216,16), to_signed(1314,16), to_signed(2974,16),
        to_signed(-1541,16), to_signed(2794,16), to_signed(-3208,16), to_signed(-1514,16), to_signed(-6433,16), to_signed(-1470,16), to_signed(2571,16), to_signed(-2462,16),
        to_signed(7054,16), to_signed(3890,16), to_signed(3456,16), to_signed(-7419,16), to_signed(-8192,16), to_signed(-5703,16), to_signed(7795,16), to_signed(-4521,16),
        to_signed(-4667,16), to_signed(-703,16), to_signed(2039,16), to_signed(2900,16), to_signed(-2599,16), to_signed(8192,16), to_signed(6651,16), to_signed(486,16),
        to_signed(8192,16), to_signed(5842,16), to_signed(2099,16), to_signed(-5785,16), to_signed(8192,16), to_signed(-6647,16), to_signed(8192,16), to_signed(6057,16),
        to_signed(-5367,16), to_signed(4488,16), to_signed(-3843,16), to_signed(-5212,16), to_signed(-4733,16), to_signed(-898,16), to_signed(5280,16), to_signed(-8192,16),
        to_signed(8192,16), to_signed(3835,16), to_signed(6383,16), to_signed(-6482,16), to_signed(-8192,16), to_signed(-5515,16), to_signed(-1448,16), to_signed(48,16),
        to_signed(-4578,16), to_signed(1604,16), to_signed(-125,16), to_signed(6546,16), to_signed(-8192,16), to_signed(8192,16), to_signed(-606,16), to_signed(-4239,16),
        to_signed(7559,16), to_signed(5379,16), to_signed(4372,16), to_signed(-5000,16), to_signed(8192,16), to_signed(-6884,16), to_signed(7129,16), to_signed(1520,16),
        to_signed(-4617,16), to_signed(6161,16), to_signed(-4776,16), to_signed(-4370,16), to_signed(-4289,16), to_signed(-221,16), to_signed(2040,16), to_signed(-8192,16),
        to_signed(8192,16), to_signed(5841,16), to_signed(7165,16), to_signed(-7480,16), to_signed(-7613,16), to_signed(-6947,16), to_signed(-2683,16), to_signed(1174,16),
        to_signed(-3412,16), to_signed(-2588,16), to_signed(960,16), to_signed(7308,16), to_signed(-8192,16), to_signed(8192,16), to_signed(68,16), to_signed(-5987,16),
        to_signed(-2214,16), to_signed(293,16), to_signed(1791,16), to_signed(5030,16), to_signed(-1705,16), to_signed(3575,16), to_signed(-4889,16), to_signed(4226,16),
        to_signed(2539,16), to_signed(-3129,16), to_signed(3364,16), to_signed(2515,16), to_signed(1346,16), to_signed(6423,16), to_signed(-5819,16), to_signed(3329,16),
        to_signed(-8192,16), to_signed(-2334,16), to_signed(1602,16), to_signed(6690,16), to_signed(3286,16), to_signed(8192,16), to_signed(-111,16), to_signed(7189,16),
        to_signed(2326,16), to_signed(5642,16), to_signed(759,16), to_signed(-4358,16), to_signed(4651,16), to_signed(-6327,16), to_signed(-1728,16), to_signed(4213,16),
        to_signed(6753,16), to_signed(1765,16), to_signed(2335,16), to_signed(-8192,16), to_signed(-3000,16), to_signed(8190,16), to_signed(8192,16), to_signed(-4930,16),
        to_signed(-3848,16), to_signed(8192,16), to_signed(-5910,16), to_signed(1956,16), to_signed(103,16), to_signed(-8192,16), to_signed(8192,16), to_signed(-2321,16),
        to_signed(2077,16), to_signed(-3892,16), to_signed(4212,16), to_signed(-8183,16), to_signed(-7184,16), to_signed(-8192,16), to_signed(7992,16), to_signed(-8192,16),
        to_signed(-5519,16), to_signed(1177,16), to_signed(4335,16), to_signed(8192,16), to_signed(-4603,16), to_signed(-4189,16), to_signed(6612,16), to_signed(6195,16),
        to_signed(-5094,16), to_signed(-4159,16), to_signed(1114,16), to_signed(2836,16), to_signed(-8192,16), to_signed(2104,16), to_signed(-3970,16), to_signed(-209,16),
        to_signed(3422,16), to_signed(-4138,16), to_signed(958,16), to_signed(1513,16), to_signed(-484,16), to_signed(1862,16), to_signed(-1233,16), to_signed(5337,16),
        to_signed(-8192,16), to_signed(-2343,16), to_signed(1003,16), to_signed(4260,16), to_signed(5398,16), to_signed(1339,16), to_signed(-825,16), to_signed(1474,16),
        to_signed(1978,16), to_signed(766,16), to_signed(-442,16), to_signed(-3047,16), to_signed(4779,16), to_signed(-8192,16), to_signed(-2256,16), to_signed(4201,16),
        to_signed(-8192,16), to_signed(-5584,16), to_signed(-7833,16), to_signed(4104,16), to_signed(-8192,16), to_signed(7832,16), to_signed(-8192,16), to_signed(-2705,16),
        to_signed(5748,16), to_signed(-2830,16), to_signed(5165,16), to_signed(3400,16), to_signed(3594,16), to_signed(528,16), to_signed(-4120,16), to_signed(8192,16),
        to_signed(-8192,16), to_signed(-2016,16), to_signed(-2973,16), to_signed(6597,16), to_signed(7887,16), to_signed(8192,16), to_signed(2820,16), to_signed(2091,16),
        to_signed(4961,16), to_signed(-720,16), to_signed(-1810,16), to_signed(-8192,16), to_signed(8192,16), to_signed(-8192,16), to_signed(-1052,16), to_signed(8093,16),
        to_signed(-7409,16), to_signed(-5472,16), to_signed(-6014,16), to_signed(7113,16), to_signed(-8192,16), to_signed(7959,16), to_signed(-8192,16), to_signed(-4775,16),
        to_signed(5450,16), to_signed(-2977,16), to_signed(951,16), to_signed(-363,16), to_signed(3508,16), to_signed(285,16), to_signed(-5289,16), to_signed(7306,16),
        to_signed(-8192,16), to_signed(-3985,16), to_signed(-7266,16), to_signed(8192,16), to_signed(7057,16), to_signed(8192,16), to_signed(2902,16), to_signed(2191,16),
        to_signed(5856,16), to_signed(1432,16), to_signed(-3926,16), to_signed(-8192,16), to_signed(8192,16), to_signed(-8192,16), to_signed(-4205,16), to_signed(6888,16),
        to_signed(2781,16), to_signed(4364,16), to_signed(-648,16), to_signed(-6245,16), to_signed(44,16), to_signed(-3330,16), to_signed(7819,16), to_signed(-1141,16),
        to_signed(-821,16), to_signed(3210,16), to_signed(-4554,16), to_signed(-1921,16), to_signed(-1411,16), to_signed(-3755,16), to_signed(5464,16), to_signed(-1056,16),
        to_signed(8192,16), to_signed(5046,16), to_signed(-2999,16), to_signed(-7546,16), to_signed(-2436,16), to_signed(-5930,16), to_signed(1440,16), to_signed(-5051,16),
        to_signed(-1253,16), to_signed(-2057,16), to_signed(3719,16), to_signed(7166,16), to_signed(-1623,16), to_signed(-1787,16), to_signed(477,16), to_signed(-4401,16),
        to_signed(-7409,16), to_signed(-4040,16), to_signed(-2359,16), to_signed(4505,16), to_signed(-8192,16), to_signed(7252,16), to_signed(-4352,16), to_signed(-387,16),
        to_signed(5882,16), to_signed(-3702,16), to_signed(8192,16), to_signed(8192,16), to_signed(8192,16), to_signed(291,16), to_signed(-7653,16), to_signed(8192,16),
        to_signed(-8192,16), to_signed(-5620,16), to_signed(-4998,16), to_signed(7014,16), to_signed(8192,16), to_signed(7008,16), to_signed(8192,16), to_signed(1873,16),
        to_signed(3872,16), to_signed(2575,16), to_signed(-2048,16), to_signed(-6197,16), to_signed(8192,16), to_signed(-8192,16), to_signed(7462,16), to_signed(5871,16),
        to_signed(-8192,16), to_signed(-2701,16), to_signed(-6528,16), to_signed(1860,16), to_signed(-8192,16), to_signed(7154,16), to_signed(-2447,16), to_signed(-860,16),
        to_signed(8078,16), to_signed(-8024,16), to_signed(8164,16), to_signed(8192,16), to_signed(8192,16), to_signed(1796,16), to_signed(-4764,16), to_signed(8047,16),
        to_signed(-8192,16), to_signed(-2537,16), to_signed(-2261,16), to_signed(8192,16), to_signed(8192,16), to_signed(8098,16), to_signed(8192,16), to_signed(2018,16),
        to_signed(6140,16), to_signed(7159,16), to_signed(-2,16), to_signed(-5065,16), to_signed(7283,16), to_signed(-8192,16), to_signed(8192,16), to_signed(8192,16),
        to_signed(4095,16), to_signed(7482,16), to_signed(4172,16), to_signed(-2191,16), to_signed(8192,16), to_signed(-4841,16), to_signed(6086,16), to_signed(-1549,16),
        to_signed(4015,16), to_signed(7007,16), to_signed(-3306,16), to_signed(-5275,16), to_signed(-2305,16), to_signed(-2055,16), to_signed(2995,16), to_signed(-2317,16),
        to_signed(8192,16), to_signed(6680,16), to_signed(2055,16), to_signed(-8078,16), to_signed(-6012,16), to_signed(-2720,16), to_signed(-349,16), to_signed(-4433,16),
        to_signed(-879,16), to_signed(-1525,16), to_signed(4311,16), to_signed(5768,16), to_signed(-3481,16), to_signed(-4193,16), to_signed(-710,16), to_signed(-2849,16),
        to_signed(-7786,16), to_signed(-3067,16), to_signed(-1220,16), to_signed(5911,16), to_signed(-8192,16), to_signed(7448,16), to_signed(-6094,16), to_signed(-2222,16),
        to_signed(8090,16), to_signed(-4243,16), to_signed(7786,16), to_signed(8192,16), to_signed(8192,16), to_signed(1805,16), to_signed(-7722,16), to_signed(7997,16),
        to_signed(-8192,16), to_signed(-4515,16), to_signed(-1780,16), to_signed(8192,16), to_signed(8192,16), to_signed(6809,16), to_signed(8192,16), to_signed(4431,16),
        to_signed(6144,16), to_signed(3212,16), to_signed(-783,16), to_signed(-6373,16), to_signed(8192,16), to_signed(-8192,16), to_signed(7049,16), to_signed(6754,16),
        to_signed(-8181,16), to_signed(-3692,16), to_signed(-1346,16), to_signed(946,16), to_signed(-8192,16), to_signed(7163,16), to_signed(1551,16), to_signed(-810,16),
        to_signed(5981,16), to_signed(-6582,16), to_signed(6822,16), to_signed(8192,16), to_signed(7994,16), to_signed(3278,16), to_signed(-2143,16), to_signed(8192,16),
        to_signed(-8192,16), to_signed(-7938,16), to_signed(-5494,16), to_signed(3949,16), to_signed(6477,16), to_signed(8041,16), to_signed(5687,16), to_signed(2713,16),
        to_signed(4048,16), to_signed(4274,16), to_signed(-318,16), to_signed(-1524,16), to_signed(3818,16), to_signed(-8192,16), to_signed(7172,16), to_signed(6676,16)
    );

    constant FF2_B : bias_16 := (
        to_signed(6451,16),  to_signed(-2340,16), to_signed(-5857,16), to_signed(673,16),
        to_signed(885,16),   to_signed(3707,16),  to_signed(-5394,16), to_signed(2177,16),
        to_signed(-819,16),  to_signed(5424,16),  to_signed(1588,16),  to_signed(3203,16),
        to_signed(-201,16),  to_signed(-311,16),  to_signed(4061,16),  to_signed(3084,16)
    );

    type matrix_16x32 is array(0 to 15, 0 to 31) of signed(15 downto 0);
    signal H_reg    : matrix_16x32 := (others => (others => (others => '0')));
    signal FF_reg   : matrix_16x16 := (others => (others => (others => '0')));
    signal acc      : signed(39 downto 0) := (others => '0');

    type state_t is (IDLE, FF1_COMPUTE, FF2_COMPUTE, OUTPUT);
    signal state    : state_t := IDLE;
    signal comp_row : integer range 0 to 16 := 0;
    signal comp_col : integer range 0 to 32 := 0;
    signal elem_cnt : integer range 0 to 32 := 0;
    signal done_reg : std_logic := '0';

begin
    done  <= done_reg;
    Y_out <= FF_reg;

    process(clk)
        variable raw    : integer;
        variable result : signed(15 downto 0);
    begin
        if rising_edge(clk) then
            done_reg <= '0';
            if rst = '1' then
                state    <= IDLE;
                comp_row <= 0; comp_col <= 0; elem_cnt <= 0;
                acc      <= (others => '0');
                H_reg    <= (others => (others => (others => '0')));
                FF_reg   <= (others => (others => (others => '0')));
            else
                case state is

                    when IDLE =>
                        if start = '1' then
                            state    <= FF1_COMPUTE;
                            comp_row <= 0; comp_col <= 0; elem_cnt <= 0;
                            acc      <= (others => '0');
                        end if;

                    when FF1_COMPUTE =>
                        if elem_cnt < 16 then
                            -- FF1: (16 tokens × 16 features) × (32 × 16) weights
                            acc      <= acc + to_signed(
                                to_integer(X_in(comp_row, elem_cnt)) *
                                to_integer(FF1_W(comp_col * 16 + elem_cnt)), 40);
                            elem_cnt <= elem_cnt + 1;
                        else
                            -- Saturate + bias + ReLU
                            raw := to_integer(acc(39 downto 15)) +
                                   to_integer(FF1_B(comp_col));
                            if raw > 32767 then
                                result := to_signed(32767, 16);
                            elsif raw < -32768 then
                                result := to_signed(-32768, 16);
                            else
                                result := to_signed(raw, 16);
                            end if;
                            -- ReLU
                            if result < 0 then
                                H_reg(comp_row, comp_col) <= (others => '0');
                            else
                                H_reg(comp_row, comp_col) <= result;
                            end if;
                            acc      <= (others => '0');
                            elem_cnt <= 0;
                            if comp_col < 31 then
                                comp_col <= comp_col + 1;
                            elsif comp_row < 15 then
                                comp_col <= 0;
                                comp_row <= comp_row + 1;
                            else
                                state    <= FF2_COMPUTE;
                                comp_row <= 0; comp_col <= 0; elem_cnt <= 0;
                                acc      <= (others => '0');
                            end if;
                        end if;

                    when FF2_COMPUTE =>
                        if elem_cnt < 32 then
                            -- FF2: (16 tokens × 32 hidden) × (16 × 32) weights
                            acc      <= acc + to_signed(
                                to_integer(H_reg(comp_row, elem_cnt)) *
                                to_integer(FF2_W(comp_col * 32 + elem_cnt)), 40);
                            elem_cnt <= elem_cnt + 1;
                        else
                            -- Saturate + bias
                            raw := to_integer(acc(39 downto 15)) +
                                   to_integer(FF2_B(comp_col));
                            if raw > 32767 then
                                FF_reg(comp_row, comp_col) <= to_signed(32767, 16);
                            elsif raw < -32768 then
                                FF_reg(comp_row, comp_col) <= to_signed(-32768, 16);
                            else
                                FF_reg(comp_row, comp_col) <= to_signed(raw, 16);
                            end if;
                            acc      <= (others => '0');
                            elem_cnt <= 0;
                            if comp_col < 15 then
                                comp_col <= comp_col + 1;
                            elsif comp_row < 15 then
                                comp_col <= 0;
                                comp_row <= comp_row + 1;
                            else
                                state <= OUTPUT;
                            end if;
                        end if;

                    when OUTPUT =>
                        done_reg <= '1';
                        state    <= IDLE;

                    when others =>
                        state <= IDLE;
                end case;
            end if;
        end if;
    end process;
end Behavioral;
