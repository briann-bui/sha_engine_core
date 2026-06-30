class sha2_256_single_block_seq extends sha2_256_base_seq;
  `uvm_object_utils(sha2_256_single_block_seq)

  localparam bit [511:0] P_EMPTY_MSG_BLOCK = {
    32'h80000000, 32'h00000000, 32'h00000000, 32'h00000000,
    32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000,
    32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000,
    32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000
  };

  function new(string name = "sha2_256_single_block_seq");
    super.new(name);
  endfunction

  task body();
    send_block(1'b1, 1'b0, 1'b1, `SHA2_256_MODE_SHA2_256, P_EMPTY_MSG_BLOCK, 64'd0);
  endtask
endclass
