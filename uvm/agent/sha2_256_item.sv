class sha2_256_item extends uvm_sequence_item;
  rand bit        init;
  rand bit        next_block;
  rand bit        final_block;
  rand bit [1:0]  mode;
  rand bit [511:0] block;
  rand bit [63:0] msg_bit_len;

  bit        done;
  bit        error;
  bit        digest_valid;
  bit [255:0] digest;

  `uvm_object_utils_begin(sha2_256_item)
    `uvm_field_int(init, UVM_DEFAULT)
    `uvm_field_int(next_block, UVM_DEFAULT)
    `uvm_field_int(final_block, UVM_DEFAULT)
    `uvm_field_int(mode, UVM_DEFAULT)
    `uvm_field_int(block, UVM_DEFAULT)
    `uvm_field_int(msg_bit_len, UVM_DEFAULT)
    `uvm_field_int(done, UVM_DEFAULT)
    `uvm_field_int(error, UVM_DEFAULT)
    `uvm_field_int(digest_valid, UVM_DEFAULT)
    `uvm_field_int(digest, UVM_DEFAULT)
  `uvm_object_utils_end

  constraint c_legal_mode { mode inside {`SHA2_256_MODE_SHA2_256, `SHA2_256_MODE_SHA224}; }

  function new(string name = "sha2_256_item");
    super.new(name);
    init        = 1'b1;
    next_block  = 1'b0;
    final_block = 1'b1;
    mode        = `SHA2_256_MODE_SHA2_256;
    block       = '0;
    msg_bit_len = '0;
  endfunction
endclass
