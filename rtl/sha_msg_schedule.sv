//-----------------------------------------------------------------------------
// Module   : sha_msg_schedule
// Project  : SHA-256 Engine IP Core
// Description:
//   Message schedule (W[t]) generator for SHA-256.
//   Uses a 16-word sliding window register to minimize area.
//
//   Operation:
//   - On LOAD: W[0..15] are loaded from the 512-bit input block.
//     Big-endian word order: W[0] = block[511:480], W[15] = block[31:0].
//   - On each ROUND cycle:
//     * Output Wt = w_reg[0] (the oldest word in the window).
//     * Compute new word: sigma1(w_reg[14]) + w_reg[9] + sigma0(w_reg[1]) + w_reg[0]
//     * Shift the window left: w_reg[i] <= w_reg[i+1], w_reg[15] <= new_word.
//
//   This produces the correct W[t] sequence for all 64 rounds without
//   storing all 64 expanded words.
//-----------------------------------------------------------------------------

module sha_msg_schedule
  import sha_pkg::*;
  import sha_func_pkg::*;
(
  input  logic        i_clk,
  input  logic        i_rst_n,

  // Control signals
  input  logic        i_load,       // Load 512-bit block into W registers
  input  logic        i_round_en,   // Enable shift/compute for one round

  // Data inputs
  input  logic [P_SHA256_BLOCK_W-1:0] i_block,  // 512-bit message block

  // Data output
  output logic [P_SHA256_WORD_W-1:0]  o_wt      // Current message schedule word
);

  // ---------------------------------------------------------------------------
  // Internal Registers: 16-word sliding window
  // ---------------------------------------------------------------------------
  logic [P_SHA256_WORD_W-1:0] r_w [0:P_SHA256_WORDS_N-1];

  // ---------------------------------------------------------------------------
  // Internal Combinational: next expanded word
  // ---------------------------------------------------------------------------
  logic [P_SHA256_WORD_W-1:0] w_new_word;

  // ---------------------------------------------------------------------------
  // New Word Computation (for t >= 16)
  // W[t] = sigma1(W[t-2]) + W[t-7] + sigma0(W[t-15]) + W[t-16]
  // Mapped to sliding window indices:
  //   W[t-16] = r_w[0],  W[t-15] = r_w[1]
  //   W[t-7]  = r_w[9],  W[t-2]  = r_w[14]
  // ---------------------------------------------------------------------------
  always_comb begin
    w_new_word = f_small_sigma1(r_w[14]) + r_w[9]
               + f_small_sigma0(r_w[1])  + r_w[0];
  end

  // ---------------------------------------------------------------------------
  // Output: current Wt is always the head of the window
  // ---------------------------------------------------------------------------
  always_comb begin
    o_wt = r_w[0];
  end

  // ---------------------------------------------------------------------------
  // Sequential Logic: Load or shift the sliding window
  // ---------------------------------------------------------------------------
  always_ff @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
      for (int i = 0; i < P_SHA256_WORDS_N; i++) begin
        r_w[i] <= '0;
      end
    end else if (i_load) begin
      // Load block words in big-endian order
      // W[0] = block[511:480], W[1] = block[479:448], ..., W[15] = block[31:0]
      for (int i = 0; i < P_SHA256_WORDS_N; i++) begin
        r_w[i] <= i_block[(P_SHA256_WORDS_N - 1 - i)*P_SHA256_WORD_W +: P_SHA256_WORD_W];
      end
    end else if (i_round_en) begin
      // Shift window left, insert new computed word at the end
      for (int i = 0; i < P_SHA256_WORDS_N - 1; i++) begin
        r_w[i] <= r_w[i + 1];
      end
      r_w[P_SHA256_WORDS_N - 1] <= w_new_word;
    end
  end

endmodule : sha_msg_schedule
