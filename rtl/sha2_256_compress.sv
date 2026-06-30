module sha2_256_compress
  import sha2_256_pkg::*;
(
  input  logic        i_clk,
  input  logic        i_rst_n,

  
  input  logic        i_load,         
  input  logic        i_round_en,     
  input  logic [5:0]  i_round_index,  

  
  input  logic [P_SHA2_256_BLOCK_W-1:0] i_block,

  
  input  logic [P_SHA2_256_WORD_W-1:0]  i_a,
  input  logic [P_SHA2_256_WORD_W-1:0]  i_b,
  input  logic [P_SHA2_256_WORD_W-1:0]  i_c,
  input  logic [P_SHA2_256_WORD_W-1:0]  i_d,
  input  logic [P_SHA2_256_WORD_W-1:0]  i_e,
  input  logic [P_SHA2_256_WORD_W-1:0]  i_f,
  input  logic [P_SHA2_256_WORD_W-1:0]  i_g,
  input  logic [P_SHA2_256_WORD_W-1:0]  i_h,

  
  output logic [P_SHA2_256_WORD_W-1:0]  o_next_a,
  output logic [P_SHA2_256_WORD_W-1:0]  o_next_b,
  output logic [P_SHA2_256_WORD_W-1:0]  o_next_c,
  output logic [P_SHA2_256_WORD_W-1:0]  o_next_d,
  output logic [P_SHA2_256_WORD_W-1:0]  o_next_e,
  output logic [P_SHA2_256_WORD_W-1:0]  o_next_f,
  output logic [P_SHA2_256_WORD_W-1:0]  o_next_g,
  output logic [P_SHA2_256_WORD_W-1:0]  o_next_h
);

  
  
  
  logic [P_SHA2_256_WORD_W-1:0] w_wt;  
  logic [P_SHA2_256_WORD_W-1:0] w_kt;  

  
  
  
  sha2_256_msg_schedule u_msg_schedule (
    .i_clk       (i_clk),
    .i_rst_n     (i_rst_n),
    .i_load      (i_load),
    .i_round_en  (i_round_en),
    .i_block     (i_block),
    .o_wt        (w_wt)
  );

  
  
  
  sha2_256_constants u_constants (
    .i_round_index (i_round_index),
    .o_kt          (w_kt)
  );

  
  
  
  sha2_256_round u_round (
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

endmodule : sha2_256_compress
