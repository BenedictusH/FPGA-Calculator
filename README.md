# ELEC 4320 Project Report

# I. Introduction

The calculator is implemented in hardware using Verilog. The code in this repo are only the verilog files and have to be imported correctly to Vivado to be ran corretly. Most of the complex mathematical functions are implemented using CORDIC (Coordinate Rotation Digital Computer) algorithms. This design works for an input of 16 bit intiger and outputs a 24 bit intiger or floating point based on the operation

# II. Development Environment, Input, and Output

The project was developed using Verilog HDL and implemented using Vivado 2020.2,targeting the Basys 3 FPGA board. The Basys 3 board, equipped with on-board switches for input and a seven-segment display for output, serves as the primary hardware interface for this calculator. The primary objective of the project was to design a hardware-based calculator capable of performing a variety of mathematical operations, including basic arithmetic, trigonometric functions, logarithms, exponents, and square roots wtihout the using of any IPs for the computations, only block memory is used to store the final output so that it can be displayed on seven segment display

The user interacts with the calculator through the on-board switches, which allow the selection of operand values and the desired mathematical operation. The calculator processes inputs within the integer range of [-999, 999], values on the seven-segment display. Internally, the calculator represents results as either a 24-bit signed integer or a Q16.8 fixed-point format, depending on the operation performed.

# III. Elaboration of The Functions

The calculator uses buttons for state transitions, with a debouncer module [1]. Basic operations like addition, subtraction, and multiplication use Verilog operators, while advanced functions rely on hardware-efficient algorithms.

- **Division**: Implements a long division algorithm adapted from Project F [2], supporting fixed-point precision and handling overflow and divide-by-zero errors.
- **Power Function**: Uses a clock-based iterative method to compute results in Q16.8 format, with bounds checking for exponents [-8, 16].
- **Square Root**: Based on the non-restoring square root method [3], it calculates results over N/2 clock cycles, minimizing hardware usage.
- **CORDIC Algorithm**: Used for trigonometric, logarithmic, and exponential functions. It operates iteratively using shifts, additions, and lookups, avoiding complex multipliers. Outputs are in Q16.8 format.
  - **Trigonometric Functions**: Computes sine, cosine, and tangent with quadrant adjustments.
  - **Logarithm**: Decomposes inputs into mantissa and exponent, computes natural logarithms using CORDIC in hyperbolic mode, and combines results [5].
  - **Exponential**: Decomposes inputs for convergence, leveraging bit-shifting for efficiency.
- **Binary-to-BCD Conversion**: Uses the Double Dabble algorithm [6] for integer and fractional parts, converting binary results to seven-segment display codes.

Table 1. Cordic Scheme

<div align="center">
  <img src="images/cordic_table.png" alt="Cordic Table">
</div>

Each module has a dedicated testbench for verification.

# IV. Schematic

<!-- $--$ $60.8$ $D=L=60$ -->

<div align="center">
  <img src="images/schematic.png" alt="Schematic">
</div>

sw[12:0] are the inputs for the calculator a, b, and operation

but[2:0] are used as inputs for state transitions

led_active[3:0] is the output that controls which seven segment display to turn on

led_code[7:0] the led code that gets passed to the seven segment display

error is the error led which will turn on if the machine encounters an error

sign_led is the led used to show sign during the input stage

# V. FSM State of the Project

The core calculator component is controlled by this FSM machine

<!-- $EXECA$ $EXECB$ $\rightarrow {calc}$ $EXECC$ $done$ -->

<div align="center">
  <img src="https://web-api.textin.com/ocr_image/external/ec1bf9dee1ac88af.jpg" alt="FSM State">
</div>

EXECA: This state is where the calculator processes the user's input. The input module validates the entered signal and determines if both a and b have been correctly provided,or if only a is input for operations that require a single operand (e.g., sin, cos, tan,exponential).

EXECB: This state handles the execution of arithmetic operations. The arithmetic component computes the result and drives the calc signal high once the requested operation is complete and the result is valid.

EXECC: In this state, the binary result is converted to its BCD representation, which is then encoded into LED codes. These codes are written to a BRAM (Block RAM). Once all the codes have been successfully written, the done signal is driven high to indicate completion.

DISPLAY: In this final state, the LED clock manages the reading of LED codes stored in the BRAM for display. At this point, all calculations are complete, and the calculator must be RESET to perform a new calculation.

The FSM for multiclock math operations follow the basic sturcture of:

<div align="center">
  <img src="https://web-api.textin.com/ocr_image/external/9405e13b7ba5fe4a.jpg" alt="Multiclock FSM">
</div>

# VI. Debugging

Each of the modules has its s own testbench fle attached in the project folder, as the number is plenty in this report, we only show the simulation results core calculator module from the input stage till the output writing stage to seven segment display. For this repor we will highlight the operation that is the complex, which is the log function. In the simulation we preform the log operation of log10 50 which result is d’434 in Q16.8 or 1.6953125 in decimal value.

<!-- input module.v x debouncer.v x display.v x display led.v xled clk.v x calculator tb.v xcalculator.v x Untitled 7* ?0C $-Γ$ H Name Value 0.000 ns 500.000 ns 1,000.000 ns 1,500.000 mm 2,000,000 mm 2,500.000 ns Vsw8 sw7 sw6 sw5 sw4 Vsw3 sw2 Vsw1 sw0 but0 but1 but2 error led_active[3:0] 15 , led_code[7:0] 255 255 a[11:01 10 10 b(11:0) 50 50 result(23:0) 434 434 -->

<div align="center">
  <img src="https://web-api.textin.com/ocr_image/external/368c1202ab25c363.jpg" alt="Simulation Results 1">
</div>

<!-- input_module.v debouncer.v x display.v display led.v x led_clk.v x calculator_th.v x calculator.v Untitled 7* ?00 ados:ancs H $-5$ H Name Value 24,000.000 nm 24,500.000 nm 25,000.000 nm 25,500.000 nm 26,000.000 nm 26,500.000 nm sa8 sw7 sw6 sw5 oeoIPu P2cacd sw4 sw3 sw2 sw1 sw0 buto but1 but2 Werror led_active[3:0] 0 15 11 13 14 11 13 14 - 11 13 14 led_code[7:0] 255 255 0 159 37 73 238 0 a[11:0] 10 10 &gt;b[11:0] 50 50 result(23:0) 434 -->

<div align="center">
  <img src="https://web-api.textin.com/ocr_image/external/91476e65ac7ebe29.jpg" alt="Simulation Results 2">
</div>

# References

[1] “Verilog code for debouncing buttons on FPGA.” Accessed: Dec. 17, 2024. [Online].Available: https://www.fpga4student.com/2017/04/simple-debouncing-verilog-code-for.html

[2] W. Green, “Division in Verilog,” Project F. Accessed: Dec. 07, 2024. [Online]. Available: https://projectf.io/posts/division-in-verilog/

[3] Vipin, “Verilog Coding Tips and Tricks: Synthesizable Clocked Square Root Calculator In Verilog,” Verilog Coding Tips and Tricks. Accessed: Dec. 03, 2024. [Online]. Available: https://verilogcodes.blogspot.com/2020/12/synthesizable-clocked-square-root.html

[4] V. Universe, “Verilog code for sine cos and arctan using CORDIC Algorithm,” VLSI UNIVERSE. Accessed: Dec. 05, 2024. [Online]. Available: https://www.vlsiuniverse.com/verilog-code-for-sine-cos-and-tan-cordic/

[5] Ross Mcgowan, CORDIC Algorithm Natural Logarithm, (Mar. 14, 2022). Accessed: Dec. 07, 2024. [Online Video]. Available: https://www.youtube.com/watch?v=g03aaYg8DUU

[6] Russell, “Convert Binary to BCD using VHDL or Verilog, Double Dabbler,” Nandland.Accessed: Dec. 09, 2024. [Online]. Available: https://nandland.com/binary-to-bcd-the-double-dabbler/
