`timescale 1ns/1ps

module sha2_256_tb_top;
  import uvm_pkg::*;
  import sha2_256_uvm_pkg::*;

  bit clk;

  always #5 clk = ~clk;

  sha2_256_if sha2_256_if(.clk(clk));

  sha2_256_core dut (
    .i_sha2_256_clk          (clk),
    .i_sha2_256_rst_n        (sha2_256_if.rst_n),
    .i_sha2_256_start        (sha2_256_if.start),
    .i_sha2_256_init         (sha2_256_if.init),
    .i_sha2_256_next         (sha2_256_if.next_block),
    .i_sha2_256_final        (sha2_256_if.final_block),
    .i_sha2_256_mode         (sha2_256_if.mode),
    .i_sha2_256_block_valid  (sha2_256_if.block_valid),
    .i_sha2_256_block        (sha2_256_if.block),
    .i_sha2_256_msg_bit_len  (sha2_256_if.msg_bit_len),
    .o_sha2_256_block_ready  (sha2_256_if.block_ready),
    .o_sha2_256_busy         (sha2_256_if.busy),
    .o_sha2_256_done         (sha2_256_if.done),
    .o_sha2_256_error        (sha2_256_if.error),
    .o_sha2_256_digest_valid (sha2_256_if.digest_valid),
    .o_sha2_256_digest       (sha2_256_if.digest)
  );

  initial begin
    sha2_256_if.init_master();
    sha2_256_if.rst_n = 1'b0;
    repeat (8) @(posedge clk);
    sha2_256_if.rst_n = 1'b1;
  end

  initial begin
    uvm_config_db#(virtual sha2_256_if)::set(null, "uvm_test_top*", "vif", sha2_256_if);
    uvm_config_db#(virtual sha2_256_if)::set(null, "uvm_test_top.env.agent*", "vif", sha2_256_if);
    run_test();
  end
endmodule
