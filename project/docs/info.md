<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works


This Verilog code implements a testbench (`tb_uart_full_duplex`) to simulate and verify the operation of a **UART Transmitter module**. Its primary goal is to test reliable data transmission while preparing for potential bidirectional communication. The UART module is intended for transmitting instructions to a basic CPU based on a Von Neumann architecture.

The main UART module, instantiated as `uut`, takes inputs like `clk`, `reset`, `rx`, and `start_transmit`, and outputs signals such as `tx`, `instruction_ready`, and `transmission_done`. A 50 MHz clock (`clk`) is generated in the testbench using a toggling mechanism, and the system is reset for 100 ns to initialize all states.

A key feature is the `send_instruction` task, which simulates the transmission of a **15-bit instruction** through the `rx` line. This involves sending a start bit (low), 15 data bits (LSB first), and a stop bit (high). Each bit period corresponds to 8680 ns, emulating a baud rate of **115200 bps**.

## How to test

To test the project, follow these steps:

1. **Simulate on EDA Playground:** Ensure the code runs correctly in an [EDA Playground](edaplayground.com) environment, using the provided testbench to verify functionality.

2. **Harden Locally:** Harden your project locally by following the instructions provided in the subsequent sections.

3. **Run GitHub Actions:** Push your changes to the repository and execute the GitHub Actions workflow. If it completes successfully, your files are ready for tapeout!


## Setup Instructions for Tiny Tapeout Environment
Github actions run after every commit to harden the project automatically. However, even though it's useful to have the GitHub action doing the work for us, it also make things take a bit longer if we're iterating a lot. You might want to harden your design locally.


### Local Hardening

We are using a different version of the PDK and OpenLane, so you’ll need to install them. This will require about **2.5GB of space**.

We need  to set up the correct environment variables. Enter the `setup_env.sh`file and modify the `install_dir` variable to the path of the directory where you want to install the enviroment (usually where you will be running your project from).

```bash
install_dir=<where you want to install>

export OPENLANE_ROOT=$install_dir/tt_openlane
export PDK_ROOT=$install_dir/tt_pdk
export PDK=sky130A
export OPENLANE_TAG=2024.04.02
export OPENLANE_IMAGE_NAME=efabless/openlane:2024.04.02
```

Source the file and check that the environment variables are correct.

```bash
./setup_env.sh #run this from the main directory
```
### Environment Variables

Source the setup file and ensure the environment variables are correctly configured. This allows you to work on a Tiny Tapeout design by sourcing the setup file.

### Clone the tt-support-tools Repository

Clone the `tt-support-tools` repository (`tt10 branch) inside the `tt` directory of your project:

```bash
cd <your project’s directory>

git clone -b tt10 https://github.com/TinyTapeout/tt-support-tools tt
```

## Python and Pip Dependencies

Ensure you have Python 3.8 or newer installed. Use a virtual environment to isolate the setup from the rest of your system:

```bash
cd <your project’s directory>

python -m venv venv

source venv/bin/activate
```

Then, install the required dependencies:

```bash
pip install -r tt/requirements.txt
```

### Install OpenLane

Run the following commands to install OpenLane:

```bash
git clone --depth=1 --branch $OPENLANE_TAG https://github.com/The-OpenROAD-Project/OpenLane.git $OPENLANE_ROOT

cd $OPENLANE_ROOT

make
```

Alternatively, you can follow [this guide](https://www.tinytapeout.com/guides/local-hardening/).

## Harden Your Project

Congratulations! You are now ready to harden your project locally.

### Generate OpenLane Configuration File

Run the following command to create the OpenLane configuration file:

```bash
cd ~/<your project directory>

./tt/tt_tool.py --create-user-config
```

This generates a `user_config.tcl` file in the `./src` directory, which lists all source files and provides a DEF template for the size and ports of the tile.

### Harden the Project Locally

To harden your project, run:

```bash
./tt/tt_tool.py --harden
```

You will see OpenLane running, and the results will be available in the `./runs/wokwi` directory.

### Check for Synthesis/Clock Warnings

Run the following command to check for any synthesis or clock warnings:

```bash
./tt/tt_tool.py --print-warnings
```

