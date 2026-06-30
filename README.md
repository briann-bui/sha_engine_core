# SHA-256 Engine IP Core

This project is a fully synthesizable SHA-256 engine written in SystemVerilog. It is designed as a clean RTL IP core for digital hardware designs.

The current version focuses only on the SHA-256 core. It does not include a bus wrapper, padding engine, register map, or testbench.

## Features

* SHA-256 compliant with FIPS 180-4
* 512-bit pre-padded block input
* 256-bit digest output
* Supports single-block and multi-block hashing
* Uses a 16-word sliding window message schedule to reduce area
* Fully synthesizable RTL
* No latches, `initial` blocks, delays, classes, or other non-synthesizable constructs

## Architecture

The core is split into several simple RTL blocks:

* `sha256_core`: top-level module
* `sha_ctrl`: FSM controller
* `sha_datapath`: hash state and working registers
* `sha_msg_schedule`: generates the message schedule W[t]
* `sha_round`: combinational SHA-256 round logic
* `sha_constants`: round constant lookup table
* `sha_func`: SHA-256 helper functions such as ROTR, Ch, Maj, Σ0, Σ1, σ0, and σ1

## File Structure

```text
sha_engine_core/
├── README.md
└── rtl/
    ├── sha_pkg.sv
    ├── sha_func.sv
    ├── sha_constants.sv
    ├── sha_round.sv
    ├── sha_msg_schedule.sv
    ├── sha_compress.sv
    ├── sha_ctrl.sv
    ├── sha_datapath.sv
    └── sha256_core.sv
```

## Top-Level Interface

The top-level module is `sha256_core`.

Main control signals:

* `i_sha_start`: starts a hash operation
* `i_sha_init`: selects the first block and loads the initial hash values
* `i_sha_next`: processes the next block using the current hash state
* `i_sha_final`: marks the last block
* `i_sha_block_valid`: indicates that the input block is valid
* `o_sha_block_ready`: indicates that the core is ready for a new block
* `o_sha_busy`: shows that the core is running
* `o_sha_done`: one-cycle pulse when the operation is complete
* `o_sha_digest_valid`: indicates that the digest output is valid
* `o_sha_digest`: 256-bit hash result

## Usage

### Single-Block Hash

For a single-block message, provide a padded 512-bit block, assert `i_sha_start`, `i_sha_init`, `i_sha_final`, and `i_sha_block_valid`, then wait for `o_sha_done`.

The digest is valid when `o_sha_digest_valid` is high.

### Multi-Block Hash

For the first block, assert `i_sha_init`.

For the following block, assert `i_sha_next`.

For the last block, assert `i_sha_final`.

The core keeps the internal hash state between blocks, so multi-block SHA-256 hashing is supported.

## Data Format

The input block uses big-endian word order:

```text
W[0]  = i_sha_block[511:480]
W[1]  = i_sha_block[479:448]
...
W[15] = i_sha_block[31:0]
```

The digest output is also big-endian:

```text
{H0, H1, H2, H3, H4, H5, H6, H7}
```

## Current Limitations

The following items are not included in this version:

* Padding engine
* APB, AHB, or AXI bus wrapper
* CSR register map
* DMA or streaming interface
* Testbench and test vectors
* Full SHA-224 support

SHA-224 currently only has placeholder initial hash values. Output truncation is not implemented yet.

## Compile Order

```text
sha_pkg.sv
sha_func.sv
sha_constants.sv
sha_round.sv
sha_msg_schedule.sv
sha_compress.sv
sha_ctrl.sv
sha_datapath.sv
sha256_core.sv
```

## Author

Linkedin: [Bui Minh Nhut](https://www.linkedin.com/in/buiminhnhut114/)
