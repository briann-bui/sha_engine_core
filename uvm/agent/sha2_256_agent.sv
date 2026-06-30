class sha2_256_agent extends uvm_agent;
  `uvm_component_utils(sha2_256_agent)

  sha2_256_sequencer sequencer;
  sha2_256_driver    driver;
  sha2_256_monitor   monitor;

  function new(string name = "sha2_256_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    sequencer = sha2_256_sequencer::type_id::create("sequencer", this);
    driver    = sha2_256_driver::type_id::create("driver", this);
    monitor   = sha2_256_monitor::type_id::create("monitor", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    driver.seq_item_port.connect(sequencer.seq_item_export);
  endfunction
endclass
