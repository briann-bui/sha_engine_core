//-----------------------------------------------------------------------------
// Module   : sha_compress
// Project  : SHA-256 Engine IP Core
// Description:
//   Compression function wrapper that integrates the message schedule,
//   round constants, and round computation into a single reusable block.
//
//   This module serves as an alternative integration point that bundles:
//     - sha_msg_schedule  : W[t] generation via 16-word sliding window
//     - sha_constants     : K[t] round constant lookup
//     - sha_round         : Single-round combinational computation
//
//   In the current design, sha_datapath instances these sub-modules directly
//   for clarity. This wrapper provides a convenient encapsulation for reuse
//   in alternative architectures (e.g., pipelined or multi-engine designs).
//-----------------------------------------------------------------------------

module sha_compress
  import sha_pkg::*;
(
  input  logic        i_clk,
  input  logic        i_rst_n,

  // Control
  input  logic        i_load,         // Load message block
  input  logic        i_round_en,     // Enable one compression round
  input  logic [5:0]  i_round_index,  // Current round index (0..63)

  // Message block input
  input  logic [P_SHA256_BLOCK_W-1:0] i_block,

  // Current working variables input
  input  logic [P_SHA256_WORD_W-1:0]  i_a,
  input  logic [P_SHA256_WORD_W-1:0]  i_b,
  input  logic [P_SHA256_WORD_W-1:0]  i_c,
  input  logic [P_SHA256_WORD_W-1:0]  i_d,
  input  logic [P_SHA256_WORD_W-1:0]  i_e,
  input  logic [P_SHA256_WORD_W-1:0]  i_f,
  input  logic [P_SHA256_WORD_W-1:0]  i_g,
  input  logic [P_SHA256_WORD_W-1:0]  i_h,

  // Next working variables output
  output logic [P_SHA256_WORD_W-1:0]  o_next_a,
  output logic [P_SHA256_WORD_W-1:0]  o_next_b,
  output logic [P_SHA256_WORD_W-1:0]  o_next_c,
  output logic [P_SHA256_WORD_W-1:0]  o_next_d,
  output logic [P_SHA256_WORD_W-1:0]  o_next_e,
  output logic [P_SHA256_WORD_W-1:0]  o_next_f,
  output logic [P_SHA256_WORD_W-1:0]  o_next_g,
  output logic [P_SHA256_WORD_W-1:0]  o_next_h
);

  // ---------------------------------------------------------------------------
  // Internal Wires
  // ---------------------------------------------------------------------------
  logic [P_SHA256_WORD_W-1:0] w_wt;  // Current message schedule word
  logic [P_SHA256_WORD_W-1:0] w_kt;  // Current round constant

  // ---------------------------------------------------------------------------
  // Message Schedule Instance
  // ---------------------------------------------------------------------------
  sha_msg_schedule u_msg_schedule (
    .i_clk       (i_clk),
    .i_rst_n     (i_rst_n),
    .i_load      (i_load),
    .i_round_en  (i_round_en),
    .i_block     (i_block),
    .o_wt        (w_wt)
  );

  // ---------------------------------------------------------------------------
  // Round Constants Instance
  // ---------------------------------------------------------------------------
  sha_constants u_constants (
    .i_round_index (i_round_index),
    .o_kt          (w_kt)
  );

  // ---------------------------------------------------------------------------
  // Round Computation Instance
  // ---------------------------------------------------------------------------
  sha_round u_round (
    .i_a      (i_a),
    .i_b      (i_b),
    .i_c      (i_c),
    .i_d      (i_d),
    .i_e      (i_e),
    .i_f      (i_f),
    .i_g      (i_g),
    .i_h      (i_h),
    .i_wt     (w_wt),
    .i_kt     (w_kt),
    .o_next_a (o_next_a),
    .o_next_b (o_next_b),
    .o_next_c (o_next_c),
    .o_next_d (o_next_d),
    .o_next_e (o_next_e),
    .o_next_f (o_next_f),
    .o_next_g (o_next_g),
    .o_next_h (o_next_h)
  );

endmodule : sha_compress
