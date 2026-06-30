interface sha2_256_if (
  input logic clk
);
  logic         rst_n;
  logic         start;
  logic         init;
  logic         next_block;
  logic         final_block;
  logic [1:0]   mode;
  logic         block_valid;
  logic [511:0] block;
  logic [63:0]  msg_bit_len;
  logic         block_ready;
  logic         busy;
  logic         done;
  logic         error;
  logic         digest_valid;
  logic [255:0] digest;

  task automatic init_master();
    start       <= 1'b0;
    init        <= 1'b0;
    next_block  <= 1'b0;
    final_block <= 1'b0;
    mode        <= '0;
    block_valid <= 1'b0;
    block       <= '0;
    msg_bit_len <= '0;
  endtask
endinterface
