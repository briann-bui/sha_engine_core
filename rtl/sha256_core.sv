//-----------------------------------------------------------------------------
// Module   : sha256_core
// Project  : SHA-256 Engine IP Core
// Description:
//   Top-level SHA-256 engine core. Integrates the FSM controller (sha_ctrl)
//   and datapath (sha_datapath) to provide a complete SHA-256 hash engine.
//
//   Features:
//   - SHA-256 hash computation (FIPS 180-4 compliant)
//   - SHA-224 initial hash value placeholder (mode 2'b01)
//   - Multi-block message support via init/next protocol
//   - 512-bit pre-padded message block input
//   - 256-bit digest output
//
//   Interface protocol:
//   1. Assert i_sha_start with i_sha_init for first block, i_sha_next for
//      subsequent blocks. Assert i_sha_final on the last block.
//   2. Provide 512-bit padded block on i_sha_block with i_sha_block_valid.
//   3. Wait for o_sha_done pulse. Check o_sha_digest_valid for final result.
//   4. Read o_sha_digest when o_sha_digest_valid is asserted.
//
//   Not included in this version:
//   - Message padding engine (blocks must be pre-padded externally)
//   - APB/AHB/AXI bus interface
//   - CSR register map
//   - DMA/memory interface
//   - Full SHA-224 truncation logic
//-----------------------------------------------------------------------------

module sha256_core
  import sha_pkg::*;
#(
  parameter int P_DATA_W   = P_SHA256_WORD_W,    // Word width (32)
  parameter int P_BLOCK_W  = P_SHA256_BLOCK_W,   // Block width (512)
  parameter int P_DIGEST_W = P_SHA256_DIGEST_W   // Digest width (256)
) (
  // Clock and Reset
  input  logic                   i_sha_clk,
  input  logic                   i_sha_rst_n,

  // Control Inputs
  input  logic                   i_sha_start,       // Start hash operation
  input  logic                   i_sha_init,        // Initialize hash (first block)
  input  logic                   i_sha_next,        // Continue hash (next block)
  input  logic                   i_sha_final,       // Final block indicator
  input  logic [1:0]             i_sha_mode,        // Mode: 00=SHA-256, 01=SHA-224

  // Data Inputs
  input  logic                   i_sha_block_valid, // Block data is valid
  input  logic [P_BLOCK_W-1:0]  i_sha_block,       // 512-bit message block
  input  logic [63:0]            i_sha_msg_bit_len, // Message bit length (for future use)

  // Status Outputs
  output logic                   o_sha_block_ready, // Ready to accept block
  output logic                   o_sha_busy,        // Engine is busy
  output logic                   o_sha_done,        // Operation complete (1-cycle pulse)
  output logic                   o_sha_error,       // Error occurred (invalid mode)

  // Digest Outputs
  output logic                   o_sha_digest_valid, // Digest is valid
  output logic [P_DIGEST_W-1:0] o_sha_digest         // 256-bit hash digest
);

  // ---------------------------------------------------------------------------
  // Internal Control Wires (ctrl → datapath)
  // ---------------------------------------------------------------------------
  logic        w_init_hash;
  logic        w_load_block;
  logic        w_round_en;
  logic        w_update_hash;
  logic        w_digest_valid_ctrl;
  logic [5:0]  w_round_index;

  // ---------------------------------------------------------------------------
  // Note: i_sha_msg_bit_len is reserved for future padding engine support.
  // Currently unused - the core expects pre-padded 512-bit blocks.
  // ---------------------------------------------------------------------------

  // ---------------------------------------------------------------------------
  // FSM Controller Instance
  // ---------------------------------------------------------------------------
  sha_ctrl u_ctrl (
    .i_clk          (i_sha_clk),
    .i_rst_n        (i_sha_rst_n),

    // External control
    .i_start        (i_sha_start),
    .i_init         (i_sha_init),
    .i_next         (i_sha_next),
    .i_final        (i_sha_final),
    .i_mode         (i_sha_mode),
    .i_block_valid  (i_sha_block_valid),

    // Status
    .o_block_ready  (o_sha_block_ready),
    .o_busy         (o_sha_busy),
    .o_done         (o_sha_done),
    .o_error        (o_sha_error),

    // Datapath control
    .o_init_hash    (w_init_hash),
    .o_load_block   (w_load_block),
    .o_round_en     (w_round_en),
    .o_update_hash  (w_update_hash),
    .o_digest_valid (w_digest_valid_ctrl),
    .o_round_index  (w_round_index)
  );

  // ---------------------------------------------------------------------------
  // Datapath Instance
  // ---------------------------------------------------------------------------
  sha_datapath u_datapath (
    .i_clk          (i_sha_clk),
    .i_rst_n        (i_sha_rst_n),

    // Control from ctrl
    .i_init_hash    (w_init_hash),
    .i_load_block   (w_load_block),
    .i_round_en     (w_round_en),
    .i_update_hash  (w_update_hash),
    .i_digest_valid (w_digest_valid_ctrl),
    .i_round_index  (w_round_index),
    .i_mode         (i_sha_mode),

    // Data
    .i_block        (i_sha_block),
    .o_digest       (o_sha_digest),
    .o_digest_valid (o_sha_digest_valid)
  );

endmodule : sha256_core
