//-----------------------------------------------------------------------------
// Module   : sha_datapath
// Project  : SHA-256 Engine IP Core
// Description:
//   Datapath for SHA-256 engine containing:
//   - Hash state registers H0-H7 (intermediate and final hash)
//   - Working variables a-h for compression rounds
//   - Instances of sha_msg_schedule, sha_round, sha_constants
//
//   Operations driven by control signals from sha_ctrl:
//   - INIT:   Load H0-H7 with initial hash values (SHA-256 or SHA-224)
//   - LOAD:   Load 512-bit block into message schedule; a-h = H0-H7
//   - ROUND:  Execute one compression round per cycle (64 total)
//   - UPDATE: H0-H7 += a-h (modulo 2^32)
//   - DIGEST: Output {H0,H1,...,H7} as the digest
//
//   Multi-block: H state is preserved between blocks (LOAD resets a-h only).
//-----------------------------------------------------------------------------

module sha_datapath
  import sha_pkg::*;
(
  input  logic        i_clk,
  input  logic        i_rst_n,

  // Control signals from sha_ctrl
  input  logic        i_init_hash,     // Load initial hash values
  input  logic        i_load_block,    // Load block, set working vars
  input  logic        i_round_en,      // Enable one compression round
  input  logic        i_update_hash,   // Update hash state H += a-h
  input  logic        i_digest_valid,  // Digest output is valid
  input  logic [5:0]  i_round_index,   // Current round (0..63)
  input  logic [1:0]  i_mode,          // SHA mode selection

  // Data input
  input  logic [P_SHA256_BLOCK_W-1:0]  i_block,  // 512-bit message block

  // Data output
  output logic [P_SHA256_DIGEST_W-1:0] o_digest,       // 256-bit hash digest
  output logic                         o_digest_valid   // Digest output valid flag
);

  // ---------------------------------------------------------------------------
  // Hash State Registers H0-H7
  // ---------------------------------------------------------------------------
  logic [P_SHA256_WORD_W-1:0] r_h [0:7];

  // ---------------------------------------------------------------------------
  // Working Variable Registers a-h
  // ---------------------------------------------------------------------------
  logic [P_SHA256_WORD_W-1:0] r_a, r_b, r_c, r_d;
  logic [P_SHA256_WORD_W-1:0] r_e, r_f, r_g, r_h_var;

  // ---------------------------------------------------------------------------
  // Internal Wires
  // ---------------------------------------------------------------------------
  logic [P_SHA256_WORD_W-1:0] w_wt;          // Message schedule word W[t]
  logic [P_SHA256_WORD_W-1:0] w_kt;          // Round constant K[t]
  logic [P_SHA256_WORD_W-1:0] w_next_a;      // Round output: next a
  logic [P_SHA256_WORD_W-1:0] w_next_b;      // Round output: next b
  logic [P_SHA256_WORD_W-1:0] w_next_c;      // Round output: next c
  logic [P_SHA256_WORD_W-1:0] w_next_d;      // Round output: next d
  logic [P_SHA256_WORD_W-1:0] w_next_e;      // Round output: next e
  logic [P_SHA256_WORD_W-1:0] w_next_f;      // Round output: next f
  logic [P_SHA256_WORD_W-1:0] w_next_g;      // Round output: next g
  logic [P_SHA256_WORD_W-1:0] w_next_h;      // Round output: next h

  // ---------------------------------------------------------------------------
  // Sub-module Instances
  // ---------------------------------------------------------------------------

  // Message Schedule: generates W[t] using 16-word sliding window
  sha_msg_schedule u_msg_schedule (
    .i_clk      (i_clk),
    .i_rst_n    (i_rst_n),
    .i_load     (i_load_block),
    .i_round_en (i_round_en),
    .i_block    (i_block),
    .o_wt       (w_wt)
  );

  // Round Constants: provides K[t] for current round
  sha_constants u_constants (
    .i_round_index (i_round_index),
    .o_kt          (w_kt)
  );

  // Round Computation: one SHA-256 compression step (combinational)
  sha_round u_round (
    .i_a      (r_a),
    .i_b      (r_b),
    .i_c      (r_c),
    .i_d      (r_d),
    .i_e      (r_e),
    .i_f      (r_f),
    .i_g      (r_g),
    .i_h      (r_h_var),
    .i_wt     (w_wt),
    .i_kt     (w_kt),
    .o_next_a (w_next_a),
    .o_next_b (w_next_b),
    .o_next_c (w_next_c),
    .o_next_d (w_next_d),
    .o_next_e (w_next_e),
    .o_next_f (w_next_f),
    .o_next_g (w_next_g),
    .o_next_h (w_next_h)
  );

  // ---------------------------------------------------------------------------
  // Hash State Register Logic (sequential)
  // ---------------------------------------------------------------------------
  always_ff @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
      for (int i = 0; i < 8; i++) begin
        r_h[i] <= '0;
      end
    end else if (i_init_hash) begin
      // Load initial hash values based on mode
      case (i_mode)
        E_MODE_SHA256: begin
          r_h[0] <= P_SHA256_H0_INIT;
          r_h[1] <= P_SHA256_H1_INIT;
          r_h[2] <= P_SHA256_H2_INIT;
          r_h[3] <= P_SHA256_H3_INIT;
          r_h[4] <= P_SHA256_H4_INIT;
          r_h[5] <= P_SHA256_H5_INIT;
          r_h[6] <= P_SHA256_H6_INIT;
          r_h[7] <= P_SHA256_H7_INIT;
        end
        E_MODE_SHA224: begin
          // SHA-224 placeholder: load SHA-224 initial values
          // Note: SHA-224 truncates output to 224 bits (H0-H6)
          r_h[0] <= P_SHA224_H0_INIT;
          r_h[1] <= P_SHA224_H1_INIT;
          r_h[2] <= P_SHA224_H2_INIT;
          r_h[3] <= P_SHA224_H3_INIT;
          r_h[4] <= P_SHA224_H4_INIT;
          r_h[5] <= P_SHA224_H5_INIT;
          r_h[6] <= P_SHA224_H6_INIT;
          r_h[7] <= P_SHA224_H7_INIT;
        end
        default: begin
          // Should not reach here (ctrl catches invalid modes)
          for (int i = 0; i < 8; i++) begin
            r_h[i] <= '0;
          end
        end
      endcase
    end else if (i_update_hash) begin
      // Update hash state: H[i] = H[i] + working_var[i] (mod 2^32)
      r_h[0] <= r_h[0] + r_a;
      r_h[1] <= r_h[1] + r_b;
      r_h[2] <= r_h[2] + r_c;
      r_h[3] <= r_h[3] + r_d;
      r_h[4] <= r_h[4] + r_e;
      r_h[5] <= r_h[5] + r_f;
      r_h[6] <= r_h[6] + r_g;
      r_h[7] <= r_h[7] + r_h_var;
    end
  end

  // ---------------------------------------------------------------------------
  // Working Variable Register Logic (sequential)
  // ---------------------------------------------------------------------------
  always_ff @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
      r_a     <= '0;
      r_b     <= '0;
      r_c     <= '0;
      r_d     <= '0;
      r_e     <= '0;
      r_f     <= '0;
      r_g     <= '0;
      r_h_var <= '0;
    end else if (i_load_block) begin
      // Initialize working variables from current hash state
      r_a     <= r_h[0];
      r_b     <= r_h[1];
      r_c     <= r_h[2];
      r_d     <= r_h[3];
      r_e     <= r_h[4];
      r_f     <= r_h[5];
      r_g     <= r_h[6];
      r_h_var <= r_h[7];
    end else if (i_round_en) begin
      // Update working variables with round computation results
      r_a     <= w_next_a;
      r_b     <= w_next_b;
      r_c     <= w_next_c;
      r_d     <= w_next_d;
      r_e     <= w_next_e;
      r_f     <= w_next_f;
      r_g     <= w_next_g;
      r_h_var <= w_next_h;
    end
  end

  // ---------------------------------------------------------------------------
  // Digest Output (combinational)
  // ---------------------------------------------------------------------------
  always_comb begin
    // Concatenate hash state in big-endian order
    o_digest = {r_h[0], r_h[1], r_h[2], r_h[3],
                r_h[4], r_h[5], r_h[6], r_h[7]};
  end

  // ---------------------------------------------------------------------------
  // Digest Valid Output (combinational, directly from ctrl)
  // ---------------------------------------------------------------------------
  always_comb begin
    o_digest_valid = i_digest_valid;
  end

endmodule : sha_datapath
