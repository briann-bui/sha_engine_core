# SHA-256 Core

SystemVerilog SHA-256 compression/hash core.

This core takes a pre-padded 512-bit block and returns a 256-bit digest. This version focuses on the RTL core and a small UVM smoke test setup. It does not include a bus wrapper or padding engine.

## Status

- SHA-256: implemented
- Multi-block hashing: supported through `init` / `next`
- Input: 512-bit pre-padded block, big-endian word order
- Output: 256-bit digest `{H0, H1, H2, H3, H4, H5, H6, H7}`
- SHA-224: initial hash values only, output truncation is not implemented yet
- Interface: direct port-level access, no APB/AHB/AXI/CSR

## Structure

```text
rtl/
  sha2_256_core.sv       top level
  sha2_256_ctrl.sv          control FSM
  sha2_256_datapath.sv      hash state and working variables
  sha2_256_msg_schedule.sv  16-word sliding window W[t]
  sha2_256_round.sv         one-round logic
  sha2_256_constants.sv     K[t] constants
  sha2_256_pkg.sv           parameters, enums, typedefs
  sha2_256_func.sv          ROTR/SHR/Ch/Maj/Sigma functions

uvm/
  Direct-port UVM smoke environment
```

Local HTML documentation is available at `docs/index.html`.

## Main Interface

```systemverilog
input  logic         i_sha2_256_clk;
input  logic         i_sha2_256_rst_n;

input  logic         i_sha2_256_start;
input  logic         i_sha2_256_init;
input  logic         i_sha2_256_next;
input  logic         i_sha2_256_final;
input  logic [1:0]   i_sha2_256_mode;        // 00: SHA-256, 01: SHA-224 placeholder

input  logic         i_sha2_256_block_valid;
input  logic [511:0] i_sha2_256_block;
input  logic [63:0]  i_sha2_256_msg_bit_len; // reserved

output logic         o_sha2_256_block_ready;
output logic         o_sha2_256_busy;
output logic         o_sha2_256_done;
output logic         o_sha2_256_error;
output logic         o_sha2_256_digest_valid;
output logic [255:0] o_sha2_256_digest;
```

## Basic Use

Single block:

```text
start=1, init=1, final=1, block_valid=1
wait done=1
read digest when digest_valid=1
```

Multi-block:

```text
block 0: start=1, init=1, final=0
block n: start=1, next=1, final=1
```

Valid modes:

```text
2'b00  SHA-256
2'b01  SHA-224 placeholder
2'b10  error
2'b11  error
```

Latency is about 68-69 cycles per block, depending on the `init` or `next` path.

## Build / Run

Synopsys VCS must be in `PATH`, or passed through the `VCS` variable.

```sh
make lint
make compile
make run
make run UVM_TEST=sha2_256_single_block_test
```

If VCS is not in `PATH`:

```sh
make run VCS=/path/to/vcs
```

Available tests:

- `sha2_256_single_block_test`
- `sha2_256_multi_block_test`
- `sha2_256_error_test`
- `sha2_256_all_test`

## Not Done Yet

- Padding engine
- Bus wrapper and CSR register map
- DMA/streaming interface
- SHA-224 output truncation
- Full regression with more golden vectors

## Author

LinkedIn: https://www.linkedin.com/in/buiminhnhut114/
