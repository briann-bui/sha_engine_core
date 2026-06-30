class sha2_256_error_seq extends sha2_256_base_seq;
  `uvm_object_utils(sha2_256_error_seq)

  function new(string name = "sha2_256_error_seq");
    super.new(name);
  endfunction

  task body();
    send_block(1'b1, 1'b0, 1'b1, `SHA2_256_MODE_RESERVED0, '0, 64'd0);
  endtask
endclass
