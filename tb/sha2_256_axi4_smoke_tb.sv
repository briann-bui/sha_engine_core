`timescale 1ns/1ps

module sha2_256_axi4_smoke_tb;
  localparam int ADDR_W = 8;
  localparam int DATA_W = 32;

  localparam logic [ADDR_W-1:0] ADDR_CTRL        = 8'h00;
  localparam logic [ADDR_W-1:0] ADDR_STATUS      = 8'h04;
  localparam logic [ADDR_W-1:0] ADDR_MSG_LEN_LO  = 8'h10;
  localparam logic [ADDR_W-1:0] ADDR_MSG_LEN_HI  = 8'h14;
  localparam logic [ADDR_W-1:0] ADDR_BLOCK_BASE  = 8'h20;
  localparam logic [ADDR_W-1:0] ADDR_DIGEST_BASE = 8'h80;

  logic               clk;
  logic               rst_n;
  logic [ADDR_W-1:0]  awaddr;
  logic [2:0]         awprot;
  logic               awvalid;
  logic               awready;
  logic [DATA_W-1:0]  wdata;
  logic [3:0]         wstrb;
  logic               wvalid;
  logic               wready;
  logic [1:0]         bresp;
  logic               bvalid;
  logic               bready;
  logic [ADDR_W-1:0]  araddr;
  logic [2:0]         arprot;
  logic               arvalid;
  logic               arready;
  logic [DATA_W-1:0]  rdata;
  logic [1:0]         rresp;
  logic               rvalid;
  logic               rready;
  logic               irq;

  logic [31:0] block_words [0:15];
  logic [31:0] digest_words [0:7];
  logic [255:0] digest;
  logic [31:0] status;
  int unsigned poll_count;

  always #5 clk = ~clk;

  sha2_256_axi4_interface #(
    .C_S_AXI_DATA_WIDTH(DATA_W),
    .C_S_AXI_ADDR_WIDTH(ADDR_W)
  ) dut (
    .i_sha2_256_aclk    (clk),
    .i_sha2_256_aresetn (rst_n),
    .i_sha2_256_awaddr  (awaddr),
    .i_sha2_256_awprot  (awprot),
    .i_sha2_256_awvalid (awvalid),
    .o_sha2_256_awready (awready),
    .i_sha2_256_wdata   (wdata),
    .i_sha2_256_wstrb   (wstrb),
    .i_sha2_256_wvalid  (wvalid),
    .o_sha2_256_wready  (wready),
    .o_sha2_256_bresp   (bresp),
    .o_sha2_256_bvalid  (bvalid),
    .i_sha2_256_bready  (bready),
    .i_sha2_256_araddr  (araddr),
    .i_sha2_256_arprot  (arprot),
    .i_sha2_256_arvalid (arvalid),
    .o_sha2_256_arready (arready),
    .o_sha2_256_rdata   (rdata),
    .o_sha2_256_rresp   (rresp),
    .o_sha2_256_rvalid  (rvalid),
    .i_sha2_256_rready  (rready),
    .o_sha2_256_irq     (irq)
  );

  task automatic axi_write(input logic [ADDR_W-1:0] addr, input logic [31:0] data);
    begin
      @(posedge clk);
      awaddr  <= addr;
      awvalid <= 1'b1;
      wdata   <= data;
      wstrb   <= 4'hF;
      wvalid  <= 1'b1;
      bready  <= 1'b1;
      wait (awready && wready);
      @(posedge clk);
      awvalid <= 1'b0;
      wvalid  <= 1'b0;
      wait (bvalid);
      if (bresp !== 2'b00) begin
        $fatal(1, "AXI write response error addr=%02h resp=%0b", addr, bresp);
      end
      @(posedge clk);
      bready <= 1'b0;
    end
  endtask

  task automatic axi_read(input logic [ADDR_W-1:0] addr, output logic [31:0] data);
    begin
      @(posedge clk);
      araddr  <= addr;
      arvalid <= 1'b1;
      rready  <= 1'b1;
      wait (arready);
      wait (rvalid);
      data = rdata;
      if (rresp !== 2'b00) begin
        $fatal(1, "AXI read response error addr=%02h resp=%0b", addr, rresp);
      end
      @(posedge clk);
      arvalid <= 1'b0;
      rready <= 1'b0;
    end
  endtask

  initial begin
    clk     = 1'b0;
    rst_n   = 1'b0;
    awaddr  = '0;
    awprot  = '0;
    awvalid = 1'b0;
    wdata   = '0;
    wstrb   = '0;
    wvalid  = 1'b0;
    bready  = 1'b0;
    araddr  = '0;
    arprot  = '0;
    arvalid = 1'b0;
    rready  = 1'b0;

    block_words[0]  = 32'h80000000;
    block_words[1]  = 32'h00000000;
    block_words[2]  = 32'h00000000;
    block_words[3]  = 32'h00000000;
    block_words[4]  = 32'h00000000;
    block_words[5]  = 32'h00000000;
    block_words[6]  = 32'h00000000;
    block_words[7]  = 32'h00000000;
    block_words[8]  = 32'h00000000;
    block_words[9]  = 32'h00000000;
    block_words[10] = 32'h00000000;
    block_words[11] = 32'h00000000;
    block_words[12] = 32'h00000000;
    block_words[13] = 32'h00000000;
    block_words[14] = 32'h00000000;
    block_words[15] = 32'h00000000;

    repeat (8) @(posedge clk);
    rst_n = 1'b1;
    repeat (2) @(posedge clk);

    for (int i = 0; i < 16; i++) begin
      axi_write(ADDR_BLOCK_BASE + (i * 4), block_words[i]);
    end

    axi_write(ADDR_MSG_LEN_LO, 32'd0);
    axi_write(ADDR_MSG_LEN_HI, 32'd0);
    axi_write(ADDR_CTRL, 32'h0000_000B);

    poll_count = 0;
    do begin
      axi_read(ADDR_STATUS, status);
      poll_count++;
      if (poll_count > 200) begin
        $fatal(1, "Timeout waiting for digest_valid status=%08h", status);
      end
    end while (status[4] !== 1'b1);

    for (int i = 0; i < 8; i++) begin
      axi_read(ADDR_DIGEST_BASE + (i * 4), digest_words[i]);
    end

    digest = {
      digest_words[0], digest_words[1], digest_words[2], digest_words[3],
      digest_words[4], digest_words[5], digest_words[6], digest_words[7]
    };

    if (digest !== 256'he3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855) begin
      $fatal(1, "Digest mismatch got=%064h", digest);
    end

    $display("SHA AXI smoke PASS digest=%064h", digest);
    $finish;
  end
endmodule
