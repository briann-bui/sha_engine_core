//-----------------------------------------------------------------------------
// Module   : sha_func_pkg (in sha_func.sv)
// Project  : SHA-256 Engine IP Core
// Description:
//   Package containing synthesizable automatic functions for SHA-256:
//   ROTR, SHR, Ch, Maj, BigSigma0, BigSigma1, SmallSigma0, SmallSigma1.
//   All functions operate on 32-bit words per FIPS 180-4.
//-----------------------------------------------------------------------------

package sha_func_pkg;

  // ---------------------------------------------------------------------------
  // ROTR^n(x) - Circular right rotation of x by n bits
  // ---------------------------------------------------------------------------
  function automatic logic [31:0] f_rotr(
    input logic [31:0] x,
    input int          n
  );
    f_rotr = (x >> n) | (x << (32 - n));
  endfunction

  // ---------------------------------------------------------------------------
  // SHR^n(x) - Right shift of x by n bits
  // ---------------------------------------------------------------------------
  function automatic logic [31:0] f_shr(
    input logic [31:0] x,
    input int          n
  );
    f_shr = x >> n;
  endfunction

  // ---------------------------------------------------------------------------
  // Ch(x,y,z) = (x AND y) XOR (NOT x AND z)
  // ---------------------------------------------------------------------------
  function automatic logic [31:0] f_ch(
    input logic [31:0] x,
    input logic [31:0] y,
    input logic [31:0] z
  );
    f_ch = (x & y) ^ (~x & z);
  endfunction

  // ---------------------------------------------------------------------------
  // Maj(x,y,z) = (x AND y) XOR (x AND z) XOR (y AND z)
  // ---------------------------------------------------------------------------
  function automatic logic [31:0] f_maj(
    input logic [31:0] x,
    input logic [31:0] y,
    input logic [31:0] z
  );
    f_maj = (x & y) ^ (x & z) ^ (y & z);
  endfunction

  // ---------------------------------------------------------------------------
  // BigSigma0(x) = ROTR^2(x) XOR ROTR^13(x) XOR ROTR^22(x)
  // Used in round computation on working variable 'a'
  // ---------------------------------------------------------------------------
  function automatic logic [31:0] f_big_sigma0(
    input logic [31:0] x
  );
    f_big_sigma0 = f_rotr(x, 2) ^ f_rotr(x, 13) ^ f_rotr(x, 22);
  endfunction

  // ---------------------------------------------------------------------------
  // BigSigma1(x) = ROTR^6(x) XOR ROTR^11(x) XOR ROTR^25(x)
  // Used in round computation on working variable 'e'
  // ---------------------------------------------------------------------------
  function automatic logic [31:0] f_big_sigma1(
    input logic [31:0] x
  );
    f_big_sigma1 = f_rotr(x, 6) ^ f_rotr(x, 11) ^ f_rotr(x, 25);
  endfunction

  // ---------------------------------------------------------------------------
  // SmallSigma0(x) = ROTR^7(x) XOR ROTR^18(x) XOR SHR^3(x)
  // Used in message schedule expansion
  // ---------------------------------------------------------------------------
  function automatic logic [31:0] f_small_sigma0(
    input logic [31:0] x
  );
    f_small_sigma0 = f_rotr(x, 7) ^ f_rotr(x, 18) ^ f_shr(x, 3);
  endfunction

  // ---------------------------------------------------------------------------
  // SmallSigma1(x) = ROTR^17(x) XOR ROTR^19(x) XOR SHR^10(x)
  // Used in message schedule expansion
  // ---------------------------------------------------------------------------
  function automatic logic [31:0] f_small_sigma1(
    input logic [31:0] x
  );
    f_small_sigma1 = f_rotr(x, 17) ^ f_rotr(x, 19) ^ f_shr(x, 10);
  endfunction

endpackage : sha_func_pkg
