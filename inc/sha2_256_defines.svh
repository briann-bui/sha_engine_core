`ifndef SHA2_256_DEFINES_SVH
`define SHA2_256_DEFINES_SVH

`define SHA2_256_BLOCK_LEN             512
`define SHA2_256_DIGEST_LEN            256
`define SHA2_256_WORD_LEN              32
`define SHA2_256_ROUND_NUM             64
`define SHA2_256_BLOCK_WORDS           16

`define SHA2_256_MODE_SHA2_256           2'b00
`define SHA2_256_MODE_SHA224           2'b01
`define SHA2_256_MODE_RESERVED0        2'b10
`define SHA2_256_MODE_RESERVED1        2'b11

`define SHA2_256_IP_VERSION            32'h0001_0000

`define SHA2_256_CTRL_START_BIT        0
`define SHA2_256_CTRL_INIT_BIT         1
`define SHA2_256_CTRL_NEXT_BIT         2
`define SHA2_256_CTRL_FINAL_BIT        3
`define SHA2_256_CTRL_MODE_LSB         4
`define SHA2_256_CTRL_MODE_MSB         5

`define SHA2_256_STATUS_READY_BIT      0
`define SHA2_256_STATUS_BUSY_BIT       1
`define SHA2_256_STATUS_DONE_BIT       2
`define SHA2_256_STATUS_ERR_BIT        3
`define SHA2_256_STATUS_DIGEST_BIT     4

`endif
