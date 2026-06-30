class sha2_256_all_test extends sha2_256_base_test;
  `uvm_component_utils(sha2_256_all_test)

  function new(string name = "sha2_256_all_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    sha2_256_single_block_seq single_seq;
    sha2_256_multi_block_seq  multi_seq;
    sha2_256_error_seq        error_seq;

    phase.raise_objection(this);
    single_seq = sha2_256_single_block_seq::type_id::create("single_seq");
    multi_seq  = sha2_256_multi_block_seq::type_id::create("multi_seq");
    error_seq  = sha2_256_error_seq::type_id::create("error_seq");
    single_seq.start(env.agent.sequencer);
    multi_seq.start(env.agent.sequencer);
    error_seq.start(env.agent.sequencer);
    phase.drop_objection(this);
  endtask
endclass
