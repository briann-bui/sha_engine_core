//-----------------------------------------------------------------------------
// Module   : sha_pkg
// Project  : SHA-256 Engine IP Core
// Description:
//   Package containing SHA-256 parameters, type definitions, FSM state
//   encoding, and mode enumeration.
//-----------------------------------------------------------------------------

package sha_pkg;

  // ---------------------------------------------------------------------------
  // SHA-256 Algorithm Parameters
  // ---------------------------------------------------------------------------
  parameter int P_SHA256_BLOCK_W  = 512;   // Message block width (bits)
  parameter int P_SHA256_DIGEST_W = 256;   // Digest output width (bits)
  parameter int P_SHA256_WORD_W   = 32;    // Word width (bits)
  parameter int P_SHA256_ROUND_N  = 64;    // Number of compression rounds
  parameter int P_SHA256_WORDS_N  = 16;    // Words per block (512/32)

  // ---------------------------------------------------------------------------
  // Mode Encoding
  // ---------------------------------------------------------------------------
  typedef enum logic [1:0] {
    E_MODE_SHA256    = 2'b00,  // SHA-256 (fully supported)
    E_MODE_SHA224    = 2'b01,  // SHA-224 (placeholder, not fully implemented)
    E_MODE_RESERVED0 = 2'b10, // Reserved for future use
    E_MODE_RESERVED1 = 2'b11  // Reserved / error
  } sha_mode_e;

  // ---------------------------------------------------------------------------
  // FSM State Encoding
  // ---------------------------------------------------------------------------
  typedef enum logic [3:0] {
    S_IDLE   = 4'b0000,  // Waiting for start command
    S_INIT   = 4'b0001,  // Load initial hash values (H0-H7)
    S_LOAD   = 4'b0010,  // Load 512-bit message block, set working vars
    S_ROUND  = 4'b0011,  // Execute compression rounds (0..63)
    S_UPDATE = 4'b0100,  // Update hash state: H += working vars
    S_DIGEST = 4'b0101,  // Present digest output
    S_DONE   = 4'b0110,  // Pulse done signal
    S_ERROR  = 4'b0111   // Error state (invalid mode, etc.)
  } sha_fsm_e;

  // ---------------------------------------------------------------------------
  // SHA-256 Initial Hash Values (FIPS 180-4 Section 5.3.3)
  // ---------------------------------------------------------------------------
  parameter logic [31:0] P_SHA256_H0_INIT = 32'h6a09e667;
  parameter logic [31:0] P_SHA256_H1_INIT = 32'hbb67ae85;
  parameter logic [31:0] P_SHA256_H2_INIT = 32'h3c6ef372;
  parameter logic [31:0] P_SHA256_H3_INIT = 32'ha54ff53a;
  parameter logic [31:0] P_SHA256_H4_INIT = 32'h510e527f;
  parameter logic [31:0] P_SHA256_H5_INIT = 32'h9b05688c;
  parameter logic [31:0] P_SHA256_H6_INIT = 32'h1f83d9ab;
  parameter logic [31:0] P_SHA256_H7_INIT = 32'h5be0cd19;

  // ---------------------------------------------------------------------------
  // SHA-224 Initial Hash Values (FIPS 180-4 Section 5.3.2) - Placeholder
  // ---------------------------------------------------------------------------
  parameter logic [31:0] P_SHA224_H0_INIT = 32'hc1059ed8;
  parameter logic [31:0] P_SHA224_H1_INIT = 32'h367cd507;
  parameter logic [31:0] P_SHA224_H2_INIT = 32'h3070dd17;
  parameter logic [31:0] P_SHA224_H3_INIT = 32'hf70e5939;
  parameter logic [31:0] P_SHA224_H4_INIT = 32'hffc00b31;
  parameter logic [31:0] P_SHA224_H5_INIT = 32'h68581511;
  parameter logic [31:0] P_SHA224_H6_INIT = 32'h64f98fa7;
  parameter logic [31:0] P_SHA224_H7_INIT = 32'hbefa4fa4;

endpackage : sha_pkg
