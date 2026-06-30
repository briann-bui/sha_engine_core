class sha2_256_error_test extends sha2_256_base_test;
  `uvm_component_utils(sha2_256_error_test)

  function new(string name = "sha2_256_error_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    sha2_256_error_seq seq;
    phase.raise_objection(this);
    seq = sha2_256_error_seq::type_id::create("seq");
    seq.start(env.agent.sequencer);
    phase.drop_objection(this);
  endtask
endclass
