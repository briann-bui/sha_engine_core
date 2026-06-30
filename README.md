# SHA-256 Engine IP Core
A synthesizable SHA-256 core written in SystemVerilog, meant to be used as a clean RTL IP block in larger hardware designs. Built together with a friend.

This version only covers the core itself — no bus wrapper, padding engine, register map, or testbench yet.

Collaborator: tedduy@gmail.com
## Features

* FIPS 180-4 compliant
* Takes a pre-padded 512-bit block, outputs a 256-bit digest
* Supports both single-block and multi-block hashing
* Message schedule uses a 16-word sliding window to keep area down
* Clean synthesizable RTL — no latches, no `initial` blocks, no delays, no classes

## Architecture

* `sha256_core` – top-level module
* `sha_ctrl` – FSM controller
* `sha_datapath` – hash state and working registers
* `sha_msg_schedule` – generates W[t]
* `sha_round` – combinational round logic
* `sha_constants` – round constant lookup table
* `sha_func` – helper functions (ROTR, Ch, Maj, Σ0, Σ1, σ0, σ1)

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

Top module is `sha256_core`. Main signals:

* `i_sha_start` – starts a hash operation
* `i_sha_init` – selects the first block, loads initial hash values
* `i_sha_next` – processes the next block, keeping current state
* `i_sha_final` – marks the last block
* `i_sha_block_valid` – input block is valid
* `o_sha_block_ready` – core ready for a new block
* `o_sha_busy` – core is running
* `o_sha_done` – one-cycle pulse when done
* `o_sha_digest_valid` – digest output is valid
* `o_sha_digest` – 256-bit hash result

## Usage

**Single block:** feed in a padded 512-bit block, assert `i_sha_start`, `i_sha_init`, `i_sha_final`, and `i_sha_block_valid` together, then wait for `o_sha_done`. Digest is valid once `o_sha_digest_valid` goes high.

**Multiple blocks:** assert `i_sha_init` on the first block, `i_sha_next` on the following ones, and `i_sha_final` on the last. The core keeps internal hash state between blocks.

## Data Format
Digest output is also big-endian: `{H0, H1, ..., H7}`.

## Current Limitations

Not yet included: padding engine, bus wrapper (APB/AHB/AXI), CSR register map, DMA/streaming interface, testbench/test vectors, full SHA-224 support (init values are placeholders only, no output truncation yet).


## Author

LinkedIn: [Bui Minh Nhut](https://www.linkedin.com/in/buiminhnhut114/)
