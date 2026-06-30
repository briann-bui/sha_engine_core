class sha2_256_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(sha2_256_scoreboard)

  uvm_analysis_imp #(sha2_256_item, sha2_256_scoreboard) analysis_export;
  int unsigned done_count;
  int unsigned error_count;

  function new(string name = "sha2_256_scoreboard", uvm_component parent = null);
    super.new(name, parent);
    analysis_export = new("analysis_export", this);
  endfunction

  function void write(sha2_256_item tr);
    if (tr.done) begin
      done_count++;
      `uvm_info("SHA2_256_SB", $sformatf("done digest_valid=%0b digest=%064h", tr.digest_valid, tr.digest), UVM_LOW)
    end
    if (tr.error) begin
      error_count++;
      `uvm_info("SHA2_256_SB", "error path observed", UVM_LOW)
    end
  endfunction
endclass
