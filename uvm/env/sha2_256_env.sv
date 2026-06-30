class sha2_256_env extends uvm_env;
  `uvm_component_utils(sha2_256_env)

  sha2_256_agent      agent;
  sha2_256_scoreboard scoreboard;

  function new(string name = "sha2_256_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agent      = sha2_256_agent::type_id::create("agent", this);
    scoreboard = sha2_256_scoreboard::type_id::create("scoreboard", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    agent.monitor.ap.connect(scoreboard.analysis_export);
  endfunction
endclass
