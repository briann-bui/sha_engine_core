# SHA-256 Engine IP Core

A fully synthesizable, pure-digital SHA-256 hash engine IP core written in SystemVerilog (IEEE 1800-2017).

> **Version:** 1.0 — SHA-256 core only (no bus wrapper, no padding engine)

## Features

| Feature | Status |
|---------|--------|
| SHA-256 (FIPS 180-4) | ✅ Fully implemented |
| SHA-224 | ⚠️ Placeholder (initial hash values only) |
| Multi-block hashing | ✅ Supported via `init`/`next` protocol |
| Pre-padded 512-bit block input | ✅ |
| 256-bit digest output | ✅ |
| Sliding window message schedule | ✅ 16-word (area-efficient) |
| Synthesizable RTL | ✅ No latches, no `initial`, no `#` delays |

## Architecture

```
sha256_core (top)
├── sha_ctrl          — FSM controller (8 states, 64-round counter)
└── sha_datapath      — Hash state H0–H7, working variables a–h
    ├── sha_msg_schedule  — W[t] via 16-word sliding window
    ├── sha_round         — Single-round combinational logic
    └── sha_constants     — K[t] lookup (case statement)

sha_compress              — Optional wrapper (msg_schedule + round + constants)
sha_pkg                   — Parameters, enums, typedefs
sha_func (sha_func_pkg)   — ROTR, SHR, Ch, Maj, Σ0, Σ1, σ0, σ1
```

## File Structure

```
sha_engine_core/
├── README.md
└── rtl/
    ├── sha_pkg.sv            — Package: parameters, FSM states, mode enum
    ├── sha_func.sv           — Package: synthesizable hash functions
    ├── sha_constants.sv      — Module: K[t] round constant lookup
    ├── sha_round.sv          — Module: single SHA-256 round (combinational)
    ├── sha_msg_schedule.sv   — Module: W[t] sliding window generator
    ├── sha_compress.sv       — Module: compression wrapper
    ├── sha_ctrl.sv           — Module: FSM controller
    ├── sha_datapath.sv       — Module: hash state & working variables
    └── sha256_core.sv        — Module: top-level integration
```

## Interface

```systemverilog
module sha256_core #(
    parameter int P_DATA_W   = 32,
    parameter int P_BLOCK_W  = 512,
    parameter int P_DIGEST_W = 256
) (
    input  logic                     i_sha_clk,
    input  logic                     i_sha_rst_n,       // Active-low reset

    input  logic                     i_sha_start,       // Start operation
    input  logic                     i_sha_init,        // First block (load H init)
    input  logic                     i_sha_next,        // Next block (keep H state)
    input  logic                     i_sha_final,       // Last block
    input  logic [1:0]               i_sha_mode,        // 00=SHA-256, 01=SHA-224

    input  logic                     i_sha_block_valid,  // Block data valid
    input  logic [P_BLOCK_W-1:0]     i_sha_block,        // 512-bit padded block
    input  logic [63:0]              i_sha_msg_bit_len,   // Reserved for future use

    output logic                     o_sha_block_ready,  // Ready to accept block
    output logic                     o_sha_busy,         // Engine busy
    output logic                     o_sha_done,         // Done (1-cycle pulse)
    output logic                     o_sha_error,        // Error (invalid mode)

    output logic                     o_sha_digest_valid, // Digest is valid
    output logic [P_DIGEST_W-1:0]    o_sha_digest        // 256-bit hash output
);
```

## Mode Encoding

| Mode | Value | Status |
|------|-------|--------|
| SHA-256 | `2'b00` | ✅ Fully supported |
| SHA-224 | `2'b01` | ⚠️ Placeholder (loads SHA-224 H init, no output truncation) |
| Reserved | `2'b10` | ❌ Triggers error |
| Reserved | `2'b11` | ❌ Triggers error |

## Operation

### Single-Block Hash

```
1. Assert: i_sha_start=1, i_sha_init=1, i_sha_final=1
           i_sha_mode=2'b00, i_sha_block_valid=1, i_sha_block=<padded block>
2. Wait:   o_sha_done=1  (~67 cycles)
3. Read:   o_sha_digest when o_sha_digest_valid=1
```

### Multi-Block Hash

```
Block 1:  start=1, init=1, final=0, block_valid=1, block=<block1>
          → Wait for done=1 (digest_valid=0, H state saved)

Block N:  start=1, next=1, final=1, block_valid=1, block=<blockN>
          → Wait for done=1, read digest when digest_valid=1
```

### FSM Flow

```
IDLE → INIT → LOAD → ROUND (×64) → UPDATE → DIGEST → DONE → IDLE
         ↑                                                 │
         └─────── (next block: skip INIT) ←────────────────┘
```

### Timing

| Phase | Cycles |
|-------|--------|
| INIT | 1 |
| LOAD | 1 |
| ROUND | 64 |
| UPDATE | 1 |
| DIGEST | 1 |
| DONE | 1 |
| **Total (with init)** | **69** |
| **Total (next block)** | **68** |

## Data Format

- **Block input:** Big-endian word order
  - `W[0] = i_sha_block[511:480]`
  - `W[1] = i_sha_block[479:448]`
  - ...
  - `W[15] = i_sha_block[31:0]`
- **Digest output:** `{H0, H1, H2, H3, H4, H5, H6, H7}` (big-endian)
- **Addition:** Modulo 2^32 (natural 32-bit overflow)

## Coding Conventions

| Rule | Convention |
|------|------------|
| Language | SystemVerilog (IEEE 1800-2017) |
| Sequential | `always_ff` with `<=` (non-blocking) |
| Combinational | `always_comb` with `=` (blocking) |
| Reset | Active-low (`i_sha_rst_n`) |
| Top-level input | `i_sha_` prefix |
| Top-level output | `o_sha_` prefix |
| Internal registers | `r_` prefix |
| Internal wires | `w_` prefix |
| Parameters | `P_` prefix |
| FSM | `typedef enum logic` |
| Prohibited | Latches, `initial`, `#` delays, `class`, `force`/`release` |

## Compilation Order

```bash
# sv2v / Verilator / VCS / DC
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

## Not Yet Implemented

- **Padding engine** — blocks must be pre-padded per FIPS 180-4 externally
- **APB/AHB/AXI bus interface** — direct port-level access only
- **CSR register map** — no memory-mapped control/status registers
- **DMA/memory interface** — no burst or streaming interface
- **SHA-224 output truncation** — initial hash values loaded, but digest is full 256-bit
- **SHA-384/SHA-512** — out of scope for v1
- **Testbench / test vectors** — not included

## License

This is a personal/generic IP core. No company-specific prefix or license restrictions.

## Author

Bui Minh Nhut
