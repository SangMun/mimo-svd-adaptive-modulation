# 4x4 MIMO SVD Adaptive Modulation Simulation

## Project Overview
This project is a MATLAB-based simulation of a 4x4 MIMO communication system.
The main goal is to compare fixed modulation schemes and adaptive modulation using SVD-based subchannel decomposition.

## Main Features
- 4x4 MIMO channel generation
- SVD-based transmit and receive processing
- Fixed modulation comparison: BPSK, QPSK, 16QAM, 64QAM
- Adaptive modulation based on subchannel SINR
- Water-pouring based power allocation
- BER and Throughput performance evaluation

## System Flow
1. Generate 4x4 MIMO channel
2. Apply SVD decomposition to separate subchannels
3. Allocate power to each subchannel
4. Select modulation scheme based on SINR
5. Transmit and receive symbols
6. Calculate BER and Throughput

## Files
- `main_mimo_svd.m` : Main simulation file
- `generate_mimo_channel.m` : Generates MIMO channel matrix
- `adaptive_ctrl_svd.m` : Adaptive modulation control using SVD
- `water_pouring_on_sinr.m` : Power allocation function
- `mimo_transmit.m` : Basic MIMO transmission
- `mimo_transmit_svd.m` : SVD-based MIMO transmission
- `mimo_receive_mmse.m` : MMSE receiver
- `mimo_receive_svd.m` : SVD-based receiver
- `demodulate_and_compare.m` : Demodulation and BER calculation
- `graycode_gen.m` : Gray code generation

## Requirements
- MATLAB
- Communications Toolbox recommended

## Results
The simulation evaluates BER and throughput performance of fixed and adaptive modulation schemes in a 4x4 MIMO environment.