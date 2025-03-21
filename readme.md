# Verilog Washing Machine Controller

A synthesizable washing machine controller implemented in Verilog, featuring configurable wash cycles, safety mechanisms, and real-time state management. Ideal for FPGA implementation.

## Features
- **3 Wash Cycles**: Delicate, Normal, Heavy
- **FSM States**: Fill, Wash, Rinse, Spin, Drain, Paused
- **Safety Features**: Door lock, pause/resume on door open
- **User Interface**: Cycle selection, timer display, status LEDs

## 📂 Repository Structure
```
├── src/
│ └── washing_machine.v # Main controller module
├── testbench/
│ └── tb_washing_machine.v # Comprehensive testbench
|__simulation/
           └──simulation_log.txt.v # Simulation Results
└── README.md
└── waves.vcd # Waves dump file
```

## 📊 Results
### Example Simulation Output:
``` 
=== Test 2: Door Open During Wash at 990000 ns ===
COMPLETE | Cycle: 00 | Timer:  7 | Door Lock: 0 | Buzzer: 1
Time: 1010000 ns | State: COMPLETE | Cycle: 00 | Timer:  0 | Door Lock: 0 | Buzzer: 1
Time: 1030000 ns | State: IDLE     | Cycle: 00 | Timer:  0 | Door Lock: 0 | Buzzer: 0
Time: 7150000 ns | State: FILL     | Cycle: 00 | Timer:  0 | Door Lock: 1 | Buzzer: 0
Time: 7190000 ns | State: FILL     | Cycle: 00 | Timer:  1 | Door Lock: 1 | Buzzer: 0
Time: 7210000 ns | State: FILL     | Cycle: 00 | Timer:  2 | Door Lock: 1 | Buzzer: 0
Time: 7230000 ns | State: FILL     | Cycle: 00 | Timer:  3 | Door Lock: 1 | Buzzer: 0
Time: 7250000 ns | State: FILL     | Cycle: 00 | Timer:  4 | Door Lock: 1 | Buzzer: 0 
```
## Scripts
```
bash
```
### Compile & Run
```
iverilog -o simv src/washing_machine.v testbench/tb_washing_machine.v
vvp simv
```
### View Waves (optional)
```
gtkwave waves.vcd
```
