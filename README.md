# First Microchip Design and Tapeout at Universidad de los Andes

For my bachelor's degree project, I am designing (and taping out) the first microchip developed at Universidad de los Andes, Chile. The goal of this project is to promote and develop the electronics area within our Faculty of Engineering, creating new opportunities for future students and establishing a bridge between the Electrical Engineering and Computer Science specialties.

## Project Structure

- **[Project](./project/)**: Contains all the project files to be hardened. More information is available in [this README file](./project/docs/info.md).
- **[UART Transmission Components](./UART%20Transmission%20components/)**: Contains partial Verilog code that will enable bidirectional communication for the CPU.
- **[CPU Module](./CPU%20Module/)**: Contains partial code for the CPU.

## Work Plan

### Microchip Development

1. **Iteration 1**: GDS for partial interface between the chip and Raspberry Pi.
2. **Iteration 2**: GDS for full interface between the chip and Raspberry Pi.
3. **Iteration 3**: GDS for CPU + communication interface.

## Current Focus

### Current Task: Full Adder

Given the technical complexity of the tools being utilized, we have opted to simplify our approach by starting with more basic components and progressively scaling up. As a next step, we aim to synthesize a simple full adder. This will allow us to gain practical experience with the tools and establish a stronger foundation for subsequent, more complex designs.

## How to Contribute

Read the documentation for guidance on how to work on the different components. To work on the UART transmission modules, refer to the documentation in [here](./project/docs/info.md).

Feel free to ask any questions!

Pro tip: adding [skip-ci] to your commits should avoid running the github actions workflow.
