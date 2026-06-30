class sha2_256_sequencer extends uvm_sequencer #(sha2_256_item);
  `uvm_component_utils(sha2_256_sequencer)

  function new(string name = "sha2_256_sequencer", uvm_component parent = null);
    super.new(name, parent);
  endfunction
endclass
