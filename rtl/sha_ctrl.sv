//-----------------------------------------------------------------------------
// Module   : sha_ctrl
// Project  : SHA-256 Engine IP Core
// Description:
//   FSM controller for the SHA-256 engine. Manages the operational flow:
//   IDLE → INIT → LOAD → ROUND (×64) → UPDATE → DIGEST → DONE → IDLE
//
//   Generates control signals for the datapath and manages the round counter.
//   Handles mode validation and error detection.
//
//   Multi-block support:
//   - i_init: start new hash (load initial H values), first block
//   - i_next: continue hash with existing H state, subsequent blocks
//   - i_final: marks the last block (digest output is valid after this)
//-----------------------------------------------------------------------------

module sha_ctrl
  import sha_pkg::*;
(
  input  logic       i_clk,
  input  logic       i_rst_n,

  // External control inputs
  input  logic       i_start,
  input  logic       i_init,
  input  logic       i_next,
  input  logic       i_final,
  input  logic [1:0] i_mode,
  input  logic       i_block_valid,

  // Status outputs
  output logic       o_block_ready,
  output logic       o_busy,
  output logic       o_done,
  output logic       o_error,

  // Datapath control outputs
  output logic       o_init_hash,
  output logic       o_load_block,
  output logic       o_round_en,
  output logic       o_update_hash,
  output logic       o_digest_valid,
  output logic [5:0] o_round_index
);

  // ---------------------------------------------------------------------------
  // Internal Registers
  // ---------------------------------------------------------------------------
  sha_fsm_e          r_state;
  sha_fsm_e          r_next_state;
  logic [5:0]        r_round_cnt;
  logic              r_is_final;       // Latched final flag for current block
  logic              r_is_init;        // Latched init flag for current operation

  // ---------------------------------------------------------------------------
  // Internal Combinational Signals
  // ---------------------------------------------------------------------------
  logic              w_mode_valid;
  logic              w_round_last;

  // ---------------------------------------------------------------------------
  // Mode Validation
  // Only SHA-256 (2'b00) is fully supported. SHA-224 (2'b01) placeholder.
  // Modes 2'b10 and 2'b11 are invalid.
  // ---------------------------------------------------------------------------
  always_comb begin
    w_mode_valid = (i_mode == E_MODE_SHA256) || (i_mode == E_MODE_SHA224);
  end

  // ---------------------------------------------------------------------------
  // Round Counter Terminal Condition
  // ---------------------------------------------------------------------------
  always_comb begin
    w_round_last = (r_round_cnt == 6'(P_SHA256_ROUND_N - 1));
  end

  // ---------------------------------------------------------------------------
  // FSM Next-State Logic (combinational)
  // ---------------------------------------------------------------------------
  always_comb begin
    r_next_state = r_state;

    case (r_state)
      S_IDLE: begin
        if (i_start) begin
          if (!w_mode_valid) begin
            r_next_state = S_ERROR;
          end else if (i_init) begin
            r_next_state = S_INIT;
          end else if (i_next && i_block_valid) begin
            r_next_state = S_LOAD;
          end
          // If i_next but !i_block_valid, stay in IDLE (wait)
        end
      end

      S_INIT: begin
        // After loading initial hash values, wait for block or go to LOAD
        if (i_block_valid) begin
          r_next_state = S_LOAD;
        end
        // Stay in INIT until block is valid
      end

      S_LOAD: begin
        // Block loaded in one cycle, proceed to rounds
        r_next_state = S_ROUND;
      end

      S_ROUND: begin
        if (w_round_last) begin
          r_next_state = S_UPDATE;
        end
        // Otherwise stay in ROUND, counter increments
      end

      S_UPDATE: begin
        r_next_state = S_DIGEST;
      end

      S_DIGEST: begin
        r_next_state = S_DONE;
      end

      S_DONE: begin
        r_next_state = S_IDLE;
      end

      S_ERROR: begin
        r_next_state = S_IDLE;
      end

      default: begin
        r_next_state = S_IDLE;
      end
    endcase
  end

  // ---------------------------------------------------------------------------
  // FSM State Register (sequential)
  // ---------------------------------------------------------------------------
  always_ff @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
      r_state <= S_IDLE;
    end else begin
      r_state <= r_next_state;
    end
  end

  // ---------------------------------------------------------------------------
  // Round Counter (sequential)
  // ---------------------------------------------------------------------------
  always_ff @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
      r_round_cnt <= 6'd0;
    end else begin
      if (r_state == S_LOAD) begin
        // Reset counter when loading a new block
        r_round_cnt <= 6'd0;
      end else if (r_state == S_ROUND) begin
        r_round_cnt <= r_round_cnt + 6'd1;
      end
    end
  end

  // ---------------------------------------------------------------------------
  // Latch Final/Init Flags (sequential)
  // Capture these on start so they persist through the processing pipeline.
  // ---------------------------------------------------------------------------
  always_ff @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
      r_is_final <= 1'b0;
      r_is_init  <= 1'b0;
    end else begin
      if (r_state == S_IDLE && i_start && w_mode_valid) begin
        r_is_final <= i_final;
        r_is_init  <= i_init;
      end else if (r_state == S_INIT && i_block_valid) begin
        // Also capture final flag if asserted during INIT wait
        r_is_final <= r_is_final | i_final;
      end
    end
  end

  // ---------------------------------------------------------------------------
  // Output Control Signals (combinational, derived from state)
  // ---------------------------------------------------------------------------
  always_comb begin
    // Defaults
    o_block_ready  = 1'b0;
    o_busy         = 1'b0;
    o_done         = 1'b0;
    o_error        = 1'b0;
    o_init_hash    = 1'b0;
    o_load_block   = 1'b0;
    o_round_en     = 1'b0;
    o_update_hash  = 1'b0;
    o_digest_valid = 1'b0;
    o_round_index  = r_round_cnt;

    case (r_state)
      S_IDLE: begin
        o_block_ready = 1'b1;  // Ready to accept a new block
      end

      S_INIT: begin
        o_busy      = 1'b1;
        o_init_hash = 1'b1;    // Load initial H0-H7 values
        // Also signal block_ready during INIT since we're waiting for block
        o_block_ready = 1'b1;
      end

      S_LOAD: begin
        o_busy       = 1'b1;
        o_load_block = 1'b1;   // Load block into msg schedule, set a-h
      end

      S_ROUND: begin
        o_busy     = 1'b1;
        o_round_en = 1'b1;     // Enable round computation
      end

      S_UPDATE: begin
        o_busy        = 1'b1;
        o_update_hash = 1'b1;  // H += working variables
      end

      S_DIGEST: begin
        o_busy         = 1'b1;
        o_digest_valid = r_is_final;  // Only valid on final block
      end

      S_DONE: begin
        o_done = 1'b1;         // Pulse done for one cycle
      end

      S_ERROR: begin
        o_error = 1'b1;        // Pulse error for one cycle
      end

      default: begin
        // All outputs at default (0)
      end
    endcase
  end

endmodule : sha_ctrl
