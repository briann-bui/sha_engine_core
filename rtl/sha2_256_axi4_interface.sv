module sha2_256_axi4_interface
  import sha2_256_pkg::*;
#(
  parameter int C_S_AXI_DATA_WIDTH = 32,
  parameter int C_S_AXI_ADDR_WIDTH = 8
) (
  input  logic                              i_sha2_256_aclk,
  input  logic                              i_sha2_256_aresetn,

  input  logic [C_S_AXI_ADDR_WIDTH-1:0]     i_sha2_256_awaddr,
  input  logic [2:0]                        i_sha2_256_awprot,
  input  logic                              i_sha2_256_awvalid,
  output logic                              o_sha2_256_awready,

  input  logic [C_S_AXI_DATA_WIDTH-1:0]     i_sha2_256_wdata,
  input  logic [(C_S_AXI_DATA_WIDTH/8)-1:0] i_sha2_256_wstrb,
  input  logic                              i_sha2_256_wvalid,
  output logic                              o_sha2_256_wready,

  output logic [1:0]                        o_sha2_256_bresp,
  output logic                              o_sha2_256_bvalid,
  input  logic                              i_sha2_256_bready,

  input  logic [C_S_AXI_ADDR_WIDTH-1:0]     i_sha2_256_araddr,
  input  logic [2:0]                        i_sha2_256_arprot,
  input  logic                              i_sha2_256_arvalid,
  output logic                              o_sha2_256_arready,

  output logic [C_S_AXI_DATA_WIDTH-1:0]     o_sha2_256_rdata,
  output logic [1:0]                        o_sha2_256_rresp,
  output logic                              o_sha2_256_rvalid,
  input  logic                              i_sha2_256_rready,

  output logic                              o_sha2_256_irq
);

  localparam logic [C_S_AXI_ADDR_WIDTH-1:0] ADDR_CTRL       = 8'h00;
  localparam logic [C_S_AXI_ADDR_WIDTH-1:0] ADDR_STATUS     = 8'h04;
  localparam logic [C_S_AXI_ADDR_WIDTH-1:0] ADDR_IRQ_EN     = 8'h08;
  localparam logic [C_S_AXI_ADDR_WIDTH-1:0] ADDR_IRQ_STATUS = 8'h0C;
  localparam logic [C_S_AXI_ADDR_WIDTH-1:0] ADDR_MSG_LEN_LO = 8'h10;
  localparam logic [C_S_AXI_ADDR_WIDTH-1:0] ADDR_MSG_LEN_HI = 8'h14;
  localparam logic [C_S_AXI_ADDR_WIDTH-1:0] ADDR_BLOCK_BASE = 8'h20;
  localparam logic [C_S_AXI_ADDR_WIDTH-1:0] ADDR_DIGEST_BASE = 8'h80;
  localparam logic [C_S_AXI_ADDR_WIDTH-1:0] ADDR_VERSION    = 8'hFC;

  localparam logic [31:0] IP_VERSION = 32'h0001_0000;

  logic [C_S_AXI_ADDR_WIDTH-1:0] r_awaddr;
  logic [31:0]                   r_wdata;
  logic [3:0]                    r_wstrb;
  logic                          r_aw_valid;
  logic                          r_w_valid;
  logic                          r_bvalid;
  logic [1:0]                    r_bresp;
  logic                          r_arready;
  logic                          r_rvalid;
  logic [1:0]                    r_rresp;
  logic [31:0]                   r_rdata;

  logic [31:0]                   r_ctrl;
  logic [31:0]                   r_irq_en;
  logic [31:0]                   r_irq_status;
  logic [31:0]                   r_block_word [0:15];
  logic [31:0]                   r_digest_word [0:7];
  logic [63:0]                   r_msg_bit_len;
  logic                          r_done_sticky;
  logic                          r_error_sticky;
  logic                          r_digest_valid_sticky;

  logic                          r_core_start;
  logic                          r_core_init;
  logic                          r_core_next;
  logic                          r_core_final;
  logic [1:0]                    r_core_mode;
  logic                          r_core_block_valid;
  logic [511:0]                  w_core_block;
  logic                          w_core_block_ready;
  logic                          w_core_busy;
  logic                          w_core_done;
  logic                          w_core_error;
  logic                          w_core_digest_valid;
  logic [255:0]                  w_core_digest;
  logic                          w_write_fire;
  logic [31:0]                   w_status;
  logic [5:0]                    w_unused_prot;

  assign w_unused_prot = {i_sha2_256_awprot, i_sha2_256_arprot};

  function automatic [31:0] apply_wstrb(
    input logic [31:0] old_data,
    input logic [31:0] new_data,
    input logic [3:0]  strb
  );
    logic [31:0] result;
    begin
      result = old_data;
      for (int i = 0; i < 4; i++) begin
        if (strb[i]) begin
          result[(8 * i) +: 8] = new_data[(8 * i) +: 8];
        end
      end
      return result;
    end
  endfunction

  function automatic logic addr_in_block(input logic [C_S_AXI_ADDR_WIDTH-1:0] addr);
    return (addr >= ADDR_BLOCK_BASE) && (addr < (ADDR_BLOCK_BASE + 8'd64)) && (addr[1:0] == 2'b00);
  endfunction

  function automatic logic addr_in_digest(input logic [C_S_AXI_ADDR_WIDTH-1:0] addr);
    return (addr >= ADDR_DIGEST_BASE) && (addr < (ADDR_DIGEST_BASE + 8'd32)) && (addr[1:0] == 2'b00);
  endfunction

  function automatic [3:0] block_index(input logic [C_S_AXI_ADDR_WIDTH-1:0] addr);
    return (addr - ADDR_BLOCK_BASE) >> 2;
  endfunction

  function automatic [2:0] digest_index(input logic [C_S_AXI_ADDR_WIDTH-1:0] addr);
    return (addr - ADDR_DIGEST_BASE) >> 2;
  endfunction

  function automatic [31:0] read_data(input logic [C_S_AXI_ADDR_WIDTH-1:0] addr);
    begin
      if (addr_in_block(addr)) begin
        return r_block_word[block_index(addr)];
      end
      if (addr_in_digest(addr)) begin
        return r_digest_word[digest_index(addr)];
      end
      case (addr)
        ADDR_CTRL       : return r_ctrl;
        ADDR_STATUS     : return w_status;
        ADDR_IRQ_EN     : return r_irq_en;
        ADDR_IRQ_STATUS : return r_irq_status;
        ADDR_MSG_LEN_LO : return r_msg_bit_len[31:0];
        ADDR_MSG_LEN_HI : return r_msg_bit_len[63:32];
        ADDR_VERSION    : return IP_VERSION;
        default         : return 32'd0;
      endcase
    end
  endfunction

  assign o_sha2_256_awready = !r_aw_valid && !r_bvalid;
  assign o_sha2_256_wready  = !r_w_valid && !r_bvalid;
  assign o_sha2_256_bvalid  = r_bvalid;
  assign o_sha2_256_bresp   = r_bresp;
  assign o_sha2_256_arready = r_arready;
  assign o_sha2_256_rvalid  = r_rvalid;
  assign o_sha2_256_rresp   = r_rresp;
  assign o_sha2_256_rdata   = r_rdata;
  assign o_sha2_256_irq     = |(r_irq_en[1:0] & r_irq_status[1:0]);
  assign w_write_fire  = r_aw_valid && r_w_valid && !r_bvalid;
  assign w_status      = {27'd0, r_digest_valid_sticky, r_error_sticky, r_done_sticky, w_core_busy, w_core_block_ready};

  assign w_core_block = {
    r_block_word[0],  r_block_word[1],  r_block_word[2],  r_block_word[3],
    r_block_word[4],  r_block_word[5],  r_block_word[6],  r_block_word[7],
    r_block_word[8],  r_block_word[9],  r_block_word[10], r_block_word[11],
    r_block_word[12], r_block_word[13], r_block_word[14], r_block_word[15]
  };

  always_ff @(posedge i_sha2_256_aclk or negedge i_sha2_256_aresetn) begin
    if (!i_sha2_256_aresetn) begin
      r_awaddr   <= '0;
      r_wdata    <= 32'd0;
      r_wstrb    <= 4'd0;
      r_aw_valid <= 1'b0;
      r_w_valid  <= 1'b0;
      r_bvalid   <= 1'b0;
      r_bresp    <= 2'b00;
    end else begin
      if (o_sha2_256_awready && i_sha2_256_awvalid) begin
        r_awaddr   <= i_sha2_256_awaddr;
        r_aw_valid <= 1'b1;
      end

      if (o_sha2_256_wready && i_sha2_256_wvalid) begin
        r_wdata   <= i_sha2_256_wdata[31:0];
        r_wstrb   <= i_sha2_256_wstrb[3:0];
        r_w_valid <= 1'b1;
      end

      if (w_write_fire) begin
        r_aw_valid <= 1'b0;
        r_w_valid  <= 1'b0;
        r_bvalid   <= 1'b1;
        r_bresp    <= 2'b00;
      end else if (r_bvalid && i_sha2_256_bready) begin
        r_bvalid <= 1'b0;
      end
    end
  end

  always_ff @(posedge i_sha2_256_aclk or negedge i_sha2_256_aresetn) begin
    if (!i_sha2_256_aresetn) begin
      r_ctrl                <= 32'd0;
      r_irq_en              <= 32'd0;
      r_irq_status          <= 32'd0;
      r_msg_bit_len         <= 64'd0;
      r_done_sticky         <= 1'b0;
      r_error_sticky        <= 1'b0;
      r_digest_valid_sticky <= 1'b0;
      r_core_start          <= 1'b0;
      r_core_init           <= 1'b0;
      r_core_next           <= 1'b0;
      r_core_final          <= 1'b0;
      r_core_mode           <= E_MODE_SHA2_256;
      r_core_block_valid    <= 1'b0;
      for (int i = 0; i < 16; i++) begin
        r_block_word[i] <= 32'd0;
      end
      for (int i = 0; i < 8; i++) begin
        r_digest_word[i] <= 32'd0;
      end
    end else begin
      r_core_start       <= 1'b0;

      if (r_core_block_valid && !w_core_block_ready) begin
        r_core_block_valid <= 1'b0;
      end

      if (w_core_done) begin
        r_done_sticky      <= 1'b1;
        r_irq_status[0]    <= 1'b1;
      end

      if (w_core_error) begin
        r_error_sticky     <= 1'b1;
        r_irq_status[1]    <= 1'b1;
      end

      if (w_core_digest_valid) begin
        r_digest_valid_sticky <= 1'b1;
        for (int i = 0; i < 8; i++) begin
          r_digest_word[i] <= w_core_digest[255 - (32 * i) -: 32];
        end
      end

      if (w_write_fire) begin
        if (addr_in_block(r_awaddr)) begin
          r_block_word[block_index(r_awaddr)] <= apply_wstrb(r_block_word[block_index(r_awaddr)], r_wdata, r_wstrb);
        end else begin
          case (r_awaddr)
            ADDR_CTRL: begin
              r_ctrl[5:1] <= r_wdata[5:1];
              r_ctrl[0]   <= 1'b0;
              if (r_wdata[0] && w_core_block_ready && !w_core_busy) begin
                r_core_start       <= 1'b1;
                r_core_block_valid <= 1'b1;
                r_core_init        <= r_wdata[1];
                r_core_next        <= r_wdata[2];
                r_core_final       <= r_wdata[3];
                r_core_mode        <= r_wdata[5:4];
                r_done_sticky      <= 1'b0;
                r_error_sticky     <= 1'b0;
                r_digest_valid_sticky <= 1'b0;
              end
            end
            ADDR_STATUS: begin
              if (r_wdata[2]) begin
                r_done_sticky <= 1'b0;
              end
              if (r_wdata[3]) begin
                r_error_sticky <= 1'b0;
              end
              if (r_wdata[4]) begin
                r_digest_valid_sticky <= 1'b0;
              end
            end
            ADDR_IRQ_EN: begin
              r_irq_en <= apply_wstrb(r_irq_en, r_wdata, r_wstrb);
            end
            ADDR_IRQ_STATUS: begin
              r_irq_status <= r_irq_status & ~r_wdata;
            end
            ADDR_MSG_LEN_LO: begin
              r_msg_bit_len[31:0] <= apply_wstrb(r_msg_bit_len[31:0], r_wdata, r_wstrb);
            end
            ADDR_MSG_LEN_HI: begin
              r_msg_bit_len[63:32] <= apply_wstrb(r_msg_bit_len[63:32], r_wdata, r_wstrb);
            end
            default: begin
            end
          endcase
        end
      end
    end
  end

  always_ff @(posedge i_sha2_256_aclk or negedge i_sha2_256_aresetn) begin
    if (!i_sha2_256_aresetn) begin
      r_arready <= 1'b0;
      r_rvalid  <= 1'b0;
      r_rresp   <= 2'b00;
      r_rdata   <= 32'd0;
    end else begin
      r_arready <= 1'b0;
      if (!r_rvalid && i_sha2_256_arvalid) begin
        r_arready <= 1'b1;
        r_rvalid  <= 1'b1;
        r_rresp   <= 2'b00;
        r_rdata   <= read_data(i_sha2_256_araddr);
      end else if (r_rvalid && i_sha2_256_rready) begin
        r_rvalid <= 1'b0;
      end
    end
  end

  sha2_256_core u_sha2_256_core (
    .i_sha2_256_clk          (i_sha2_256_aclk),
    .i_sha2_256_rst_n        (i_sha2_256_aresetn),
    .i_sha2_256_start        (r_core_start),
    .i_sha2_256_init         (r_core_init),
    .i_sha2_256_next         (r_core_next),
    .i_sha2_256_final        (r_core_final),
    .i_sha2_256_mode         (r_core_mode),
    .i_sha2_256_block_valid  (r_core_block_valid),
    .i_sha2_256_block        (w_core_block),
    .i_sha2_256_msg_bit_len  (r_msg_bit_len),
    .o_sha2_256_block_ready  (w_core_block_ready),
    .o_sha2_256_busy         (w_core_busy),
    .o_sha2_256_done         (w_core_done),
    .o_sha2_256_error        (w_core_error),
    .o_sha2_256_digest_valid (w_core_digest_valid),
    .o_sha2_256_digest       (w_core_digest)
  );

endmodule : sha2_256_axi4_interface
