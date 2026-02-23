# FPGA Solana PoH verifier

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
