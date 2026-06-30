class sha2_256_monitor extends uvm_monitor;
  `uvm_component_utils(sha2_256_monitor)

  virtual sha2_256_if vif;
  uvm_analysis_port #(sha2_256_item) ap;

  function new(string name = "sha2_256_monitor", uvm_component parent = null);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual sha2_256_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal("NOVIF", "sha2_256_if is not configured")
    end
  endfunction

  task run_phase(uvm_phase phase);
    sha2_256_item tr;
    forever begin
      @(posedge vif.clk);
      if (vif.done || vif.error) begin
        tr = sha2_256_item::type_id::create("tr");
        tr.done         = vif.done;
        tr.error        = vif.error;
        tr.digest_valid = vif.digest_valid;
        tr.digest       = vif.digest;
        ap.write(tr);
      end
    end
  endtask
endclass
