# SHA-256 UVM Verification

Thu muc nay chua UVM testbench cho `sha2_256_core` qua direct port-level interface.

## Directory tree

```text
uvm/
|-- agent/
|   |-- sha2_256_agent.sv
|   |-- sha2_256_item.sv
|   `-- sha2_256_sequencer.sv
|-- driver/
|   `-- sha2_256_driver.sv
|-- env/
|   `-- sha2_256_env.sv
|-- monitor/
|   `-- sha2_256_monitor.sv
|-- scoreboard/
|   `-- sha2_256_scoreboard.sv
|-- sequences/
|   |-- sha2_256_base_seq.sv
|   |-- sha2_256_error_seq.sv
|   |-- sha2_256_multi_block_seq.sv
|   `-- sha2_256_single_block_seq.sv
|-- tb/
|   |-- sha2_256_if.sv
|   |-- sha2_256_tb_top.sv
|   `-- sha2_256_uvm_pkg.sv
|-- tests/
|   |-- sha2_256_all_test.sv
|   |-- sha2_256_base_test.sv
|   |-- sha2_256_error_test.sv
|   |-- sha2_256_multi_block_test.sv
|   `-- sha2_256_single_block_test.sv
```

## Testcases

- `sha2_256_single_block_test`: one pre-padded SHA-256 block smoke test.
- `sha2_256_multi_block_test`: two-block init/next protocol smoke test.
- `sha2_256_error_test`: reserved mode error-path smoke test.
- `sha2_256_all_test`: runs all sequences above.

## Synopsys VCS example

```sh
make lint
make compile
make run
make run UVM_TEST=sha2_256_single_block_test
```

Neu VCS chua nam trong `PATH`, truyen duong dan tool:

```sh
make run VCS=/path/to/vcs
```
