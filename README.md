# FPGA Programming

This repository provides a **minimal, fast, and fully open-source Makefile-based FPGA build system** for the **Sipeed Tang Nano 9K (GW1NR-LV9QN88PC6/I5)** development board using:

- **Yosys** → Synthesis
- **nextpnr-himbaechel (gowin)** → Place & Route
- **gowin_pack** → Bitstream generation
- **openFPGALoader** → FPGA programming

This flow avoids vendor IDEs entirely and enables **scriptable, reproducible, CI-friendly FPGA builds**.

---

## Features

- 🚀 Fully open-source toolchain
- ⚡ One-command FPGA build
- 🧱 Clean separation of synthesis, P&R, and packing
- 🔁 Optional simulation flow
- 🔌 Direct USB programming using openFPGALoader
- 📦 Minimal, readable Makefile

---

## Project Structure

```
.
├── Makefile
├── src/
│   ├── top.v       # Supports Verilog source or VHDL source (.vdl / .vhdl) but not both
├── constraints/
│   └── tangnano9k.cst
├── sim/
│   └── top_tb.v       # optional
└── build/
```

---

## Requirements

Install the **OSS CAD Suite**, which includes:

- yosys
- nextpnr-himbaechel
- gowin_pack
- openFPGALoader

### Install oss-cad-suite

```bash
cd ~
wget https://github.com/YosysHQ/oss-cad-suite-build/releases/download/2026-02-16/oss-cad-suite-linux-x64-20260216.tgz
tar -xzf oss-cad-suite-linux-x64-20260216.tgz
mv oss-cad-suite-linux-x64-20260216 oss-cad-suite
```

Add to PATH:

```bash
echo 'export PATH="$HOME/oss-cad-suite/bin:$PATH"' >> ~/.bashrc
exec bash
```

Verify:

```bash
yosys -V
nextpnr-himbaechel --help
gowin_pack -h
openFPGALoader --help
```

---

## Build Flow Overview

```
Verilog → Yosys → JSON netlist
        → nextpnr → Routed JSON
        → gowin_pack → .fs bitstream
        → openFPGALoader → FPGA
```

---

## Usage

### Build Everything (Default)

```bash
make
```

Produces:

```
build/blinky.fs
```

---

### Synthesis Only

```bash
make synth
```

---

### Place & Route Only

```bash
make pnr
```

---

### Generate Bitstream Only

```bash
make pack
```

---

### Program FPGA

```bash
make program
```

---

### Run Simulation (Optional)

Requires:

```
sim/top_tb.v
```

Run:

```bash
make sim
```

---

### Clean Build Artifacts

```bash
make clean
```

---

## Customization

### Change Project Name

```makefile
PROJECT = blinky
```

### Change Top Module

```makefile
TOP_MODULE = top
```

### Change Board Constraint File

```makefile
CONSTRAINT_FILE = constraints/tangnano9k.cst
```

---

## Example: Blinky

### Verilog

Minimal LED blinker example:

```verilog
module top (
    input  wire clk,        // 27 MHz clock input
    output wire [5:0] led   // 6 LED outputs
);

    // Counter for timing
    // 27MHz / 27M = 1 Hz blink rate
    reg [24:0] counter = 0;
    
    // LED pattern register
    reg [5:0] led_pattern = 6'b000001;
    
    // Counter logic
    always @(posedge clk) begin
        counter <= counter + 1;
        
        // Every ~0.5 seconds, shift LED pattern
        if (counter == 25'd13_500_000) begin
            counter <= 0;
            // Rotate pattern left with wrap
            led_pattern <= {led_pattern[4:0], led_pattern[5]};
        end
    end
    
    // Output assignment
    assign led = ~led_pattern;

endmodule
```

### VHDL

```vhdl
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity top is
  port (
    clk : in std_logic; -- 27 MHz clock input
    led : out std_logic_vector(5 downto 0) -- 6 LED outputs
  );
end entity top;

architecture rtl of top is
  -- Counter for timing
  -- 27MHz / 13.5M = ~0.5s per shift
  signal counter : unsigned(24 downto 0) := (others => '0');

  -- LED pattern register
  signal led_pattern : std_logic_vector(5 downto 0) := "000001";
begin

  -- Counter and shift logic
  process (clk)
  begin
    if rising_edge(clk) then
      counter <= counter + 1;

      -- Every ~0.5 seconds, shift LED pattern
      if counter = to_unsigned(13_500_000, 25) then
        counter <= (others => '0');
        -- Rotate pattern left with wrap
        led_pattern <= led_pattern(4 downto 0) & led_pattern(5);
      end if;
    end if;
  end process;

  -- Output assignment
  led <= led_pattern;

end architecture rtl;
```

---

## Toolchain Details

| Stage       | Tool               |
| ----------- | ------------------ |
| Synthesis   | yosys              |
| P&R         | nextpnr-himbaechel |
| Packing     | gowin_pack         |
| Programming | openFPGALoader     |
