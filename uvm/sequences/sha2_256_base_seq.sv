class sha2_256_base_seq extends uvm_sequence #(sha2_256_item);
  `uvm_object_utils(sha2_256_base_seq)

  function new(string name = "sha2_256_base_seq");
    super.new(name);
  endfunction

  task send_block(bit init, bit next_block, bit final_block, bit [1:0] mode, bit [511:0] block, bit [63:0] msg_bit_len = 64'd0);
    sha2_256_item tr;
    tr = sha2_256_item::type_id::create("tr");
    start_item(tr);
    tr.init        = init;
    tr.next_block  = next_block;
    tr.final_block = final_block;
    tr.mode        = mode;
    tr.block       = block;
    tr.msg_bit_len = msg_bit_len;
    finish_item(tr);
  endtask
endclass
