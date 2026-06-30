class sha2_256_base_test extends uvm_test;
  `uvm_component_utils(sha2_256_base_test)

  sha2_256_env env;

  function new(string name = "sha2_256_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = sha2_256_env::type_id::create("env", this);
  endfunction
endclass
