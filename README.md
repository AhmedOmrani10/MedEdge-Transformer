<div align="center">

# SmartCell - Project 07: Transformer Architecture on Zybo FPGA

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![FPGA](https://img.shields.io/badge/FPGA-Zybo%20Z7-blue)](https://digilent.com/reference/programmable-logic/zybo-z7/start)
[![Xilinx](https://img.shields.io/badge/Xilinx-Vivado%202023.x-orange)](https://www.xilinx.com/products/design-tools/vivado.html)
[![Python](https://img.shields.io/badge/Python-3.8+-green)](https://www.python.org/)
[![PyTorch](https://img.shields.io/badge/PyTorch-2.0+-red)](https://pytorch.org/)

**Hardware Design and Implementation of a Transformer for Edge AI on Zybo**

[Overview](#overview) • 
[Architecture](#architecture) • 
[Objectives](#objectives) • 
[Installation](#installation) • 
[Usage](#usage) • 
[Documentation](#documentation) • 
[Contributions](#contributions)

</div>

## 📋 Table of Contents
- [Overview](#overview)
- [Project Architecture](#project-architecture)
- [Technical Objectives](#technical-objectives)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Design Flow](#design-flow)
- [Results and Benchmarks](#results-and-benchmarks)
- [Documentation](#documentation)
- [Team](#team)
- [License](#license)
- [Contact](#contact)

## 🎯 Overview

This project aims to design and implement an optimized Transformer architecture on FPGA, deployed on the Zybo platform (Xilinx Zynq-7000). The goal is to accelerate Transformer model inference by exploiting the massive parallelism of FPGAs for Edge AI applications.

### Context
Transformer models have become the state of the art in many machine learning domains, but their deployment on embedded devices remains a major challenge due to their computational complexity and energy requirements. This project proposes an optimized hardware solution to address these constraints.

## 🏗 Project Architecture

### Zybo Z7 Platform (Xilinx Zynq-7000)
┌─────────────────────────────────────────────────────────────┐
│                     Zybo Z7 Board                           │
├───────────────────────────────┬─────────────────────────────┤
│   Processing System (PS)      │   Programmable Logic (PL)   │
│                               │                             │
│   ┌───────────────────────┐   │   ┌─────────────────────┐   │
│   │  ARM Cortex-A9        │   │   │  Transformer Core   │   │
│   │  Dual-Core @ 650MHz   │   │   │                     │   │
│   │                       │   │   │  ┌───────────────┐  │   │
│   │  • Model management   │   │   │  │ Multi-Head    │  │   │
│   │  • Orchestration      │◄──┼───┼──┤ Attention     │  │   │
│   │  • Preprocessing      │   │   │  │ Accelerator   │  │   │
│   │  • Post-processing    │   │   │  └───────────────┘  │   │
│   │  • User interface     │   │   │  ┌───────────────┐  │   │
│   └───────────────────────┘   │   │  │ Feed-Forward  │  │   │
│               ▲               │   │  │ Network      │  │   │
│               │ AXI4          │   │  └───────────────┘  │   │
│               ▼               │   │  ┌───────────────┐  │   │
│   ┌───────────────────────┐   │   │  │ Layer Norm    │  │   │
│   │  PS-PL Communication  │   │   │  │ & Add         │  │   │
│   │  AXI4 High-Performance│───┼───┼─▶│               │  │   │
│   │  Bus                  │   │   │  └───────────────┘  │   │
│   └───────────────────────┘   │   │  ┌───────────────┐  │   │
│                               │   │  │ DSP Slices    │  │   │
│                               │   │  │ BRAM Buffers  │  │   │
│                               │   │  └───────────────┘  │   │
└───────────────────────────────┴─────────────────────────────┘
## 🏗 Hardware Components

### Processing System (PS) : ARM Cortex-A9 dual-core
```yaml
processing_system:
  architecture: ARM Cortex-A9
  cores: 2
  frequency: 650 MHz
  memory:
    type: DDR3
    size: 512 MB
  functions:
    - Model management and computation orchestration
    - Data preprocessing and post-processing
    - User interface and communication
programmable_logic:
  fpga_family: Artix-7
  accelerator: Dedicated hardware Transformer accelerator
  dsp_slices:
    count: 80
    purpose: Matrix computations
  bram:
    blocks: 140
    purpose: Buffers and model weights
  capabilities:
    - Programmable logic for massive parallelization
