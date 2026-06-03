//-----------------------------------------------------------------------------
// Module   : sha_round
// Project  : SHA-256 Engine IP Core
// Description:
//   Purely combinational module that computes one SHA-256 compression round.
//   Given current working variables (a..h), message schedule word Wt, and
//   round constant Kt, produces next working variables (next_a..next_h).
//
//   Round computation (FIPS 180-4 Section 6.2.2):
//     T1 = h + BigSigma1(e) + Ch(e,f,g) + Kt + Wt
//     T2 = BigSigma0(a) + Maj(a,b,c)
//     next_h = g
//     next_g = f
//     next_f = e
//     next_e = d + T1
//     next_d = c
//     next_c = b
//     next_b = a
//     next_a = T1 + T2
//
//   All additions are modulo 2^32 (natural 32-bit overflow).
//-----------------------------------------------------------------------------

module sha_round
  import sha_func_pkg::*;
(
  // Current working variables
  input  logic [31:0] i_a,
  input  logic [31:0] i_b,
  input  logic [31:0] i_c,
  input  logic [31:0] i_d,
  input  logic [31:0] i_e,
  input  logic [31:0] i_f,
  input  logic [31:0] i_g,
  input  logic [31:0] i_h,

  // Round inputs
  input  logic [31:0] i_wt,   // Message schedule word W[t]
  input  logic [31:0] i_kt,   // Round constant K[t]

  // Next working variables
  output logic [31:0] o_next_a,
  output logic [31:0] o_next_b,
  output logic [31:0] o_next_c,
  output logic [31:0] o_next_d,
  output logic [31:0] o_next_e,
  output logic [31:0] o_next_f,
  output logic [31:0] o_next_g,
  output logic [31:0] o_next_h
);

  // ---------------------------------------------------------------------------
  // Internal Combinational Signals
  // ---------------------------------------------------------------------------
  logic [31:0] w_t1;  // Temporary value T1
  logic [31:0] w_t2;  // Temporary value T2

  // ---------------------------------------------------------------------------
  // Round Computation (purely combinational)
  // ---------------------------------------------------------------------------
  always_comb begin
    // T1 = h + BigSigma1(e) + Ch(e,f,g) + Kt + Wt
    w_t1 = i_h + f_big_sigma1(i_e) + f_ch(i_e, i_f, i_g) + i_kt + i_wt;

    // T2 = BigSigma0(a) + Maj(a,b,c)
    w_t2 = f_big_sigma0(i_a) + f_maj(i_a, i_b, i_c);

    // Next working variables
    o_next_a = w_t1 + w_t2;
    o_next_b = i_a;
    o_next_c = i_b;
    o_next_d = i_c;
    o_next_e = i_d + w_t1;
    o_next_f = i_e;
    o_next_g = i_f;
    o_next_h = i_g;
  end

endmodule : sha_round
