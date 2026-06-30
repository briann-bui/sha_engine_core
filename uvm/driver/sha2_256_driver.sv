class sha2_256_driver extends uvm_driver #(sha2_256_item);
  `uvm_component_utils(sha2_256_driver)

  virtual sha2_256_if vif;

  function new(string name = "sha2_256_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual sha2_256_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal("NOVIF", "sha2_256_if is not configured")
    end
  endfunction

  task run_phase(uvm_phase phase);
    sha2_256_item tr;
    vif.init_master();
    forever begin
      seq_item_port.get_next_item(tr);
      drive_one(tr);
      seq_item_port.item_done();
    end
  endtask

  task drive_one(sha2_256_item tr);
    bit accepted_or_error;

    wait (vif.rst_n === 1'b1);
    @(posedge vif.clk);
    wait (vif.block_ready === 1'b1 || vif.busy === 1'b0);

    vif.start       <= 1'b1;
    vif.init        <= tr.init;
    vif.next_block  <= tr.next_block;
    vif.final_block <= tr.final_block;
    vif.mode        <= tr.mode;
    vif.block_valid <= 1'b1;
    vif.block       <= tr.block;
    vif.msg_bit_len <= tr.msg_bit_len;

    accepted_or_error = 1'b0;
    do begin
      @(posedge vif.clk);
      accepted_or_error = (vif.error === 1'b1)
                       || ((vif.busy === 1'b1) && (vif.block_ready === 1'b0));
    end while (!accepted_or_error);

    if (vif.error !== 1'b1) begin
      @(posedge vif.clk);
    end

    vif.start       <= 1'b0;
    vif.init        <= 1'b0;
    vif.next_block  <= 1'b0;
    vif.final_block <= 1'b0;
    vif.block_valid <= 1'b0;

    wait (vif.done === 1'b1 || vif.error === 1'b1);
    @(posedge vif.clk);
  endtask
endclass
