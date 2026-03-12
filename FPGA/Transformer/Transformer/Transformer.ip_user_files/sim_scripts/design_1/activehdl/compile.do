transcript off
onbreak {quit -force}
onerror {quit -force}
transcript on

vlib work
vlib activehdl/xilinx_vip
vlib activehdl/xpm
vlib activehdl/axi_infrastructure_v1_1_0
vlib activehdl/axi_vip_v1_1_19
vlib activehdl/processing_system7_vip_v1_0_21
vlib activehdl/xil_defaultlib
vlib activehdl/xlconstant_v1_1_9
vlib activehdl/lib_cdc_v1_0_3
vlib activehdl/proc_sys_reset_v5_0_16
vlib activehdl/smartconnect_v1_0
vlib activehdl/axi_register_slice_v2_1_33

vmap xilinx_vip activehdl/xilinx_vip
vmap xpm activehdl/xpm
vmap axi_infrastructure_v1_1_0 activehdl/axi_infrastructure_v1_1_0
vmap axi_vip_v1_1_19 activehdl/axi_vip_v1_1_19
vmap processing_system7_vip_v1_0_21 activehdl/processing_system7_vip_v1_0_21
vmap xil_defaultlib activehdl/xil_defaultlib
vmap xlconstant_v1_1_9 activehdl/xlconstant_v1_1_9
vmap lib_cdc_v1_0_3 activehdl/lib_cdc_v1_0_3
vmap proc_sys_reset_v5_0_16 activehdl/proc_sys_reset_v5_0_16
vmap smartconnect_v1_0 activehdl/smartconnect_v1_0
vmap axi_register_slice_v2_1_33 activehdl/axi_register_slice_v2_1_33

vlog -work xilinx_vip  -sv2k12 "+incdir+C:/Xilinx/Vivado/2024.2/data/xilinx_vip/include" -l xilinx_vip -l xpm -l axi_infrastructure_v1_1_0 -l axi_vip_v1_1_19 -l processing_system7_vip_v1_0_21 -l xil_defaultlib -l xlconstant_v1_1_9 -l lib_cdc_v1_0_3 -l proc_sys_reset_v5_0_16 -l smartconnect_v1_0 -l axi_register_slice_v2_1_33 \
"C:/Xilinx/Vivado/2024.2/data/xilinx_vip/hdl/axi4stream_vip_axi4streampc.sv" \
"C:/Xilinx/Vivado/2024.2/data/xilinx_vip/hdl/axi_vip_axi4pc.sv" \
"C:/Xilinx/Vivado/2024.2/data/xilinx_vip/hdl/xil_common_vip_pkg.sv" \
"C:/Xilinx/Vivado/2024.2/data/xilinx_vip/hdl/axi4stream_vip_pkg.sv" \
"C:/Xilinx/Vivado/2024.2/data/xilinx_vip/hdl/axi_vip_pkg.sv" \
"C:/Xilinx/Vivado/2024.2/data/xilinx_vip/hdl/axi4stream_vip_if.sv" \
"C:/Xilinx/Vivado/2024.2/data/xilinx_vip/hdl/axi_vip_if.sv" \
"C:/Xilinx/Vivado/2024.2/data/xilinx_vip/hdl/clk_vip_if.sv" \
"C:/Xilinx/Vivado/2024.2/data/xilinx_vip/hdl/rst_vip_if.sv" \

vlog -work xpm  -sv2k12 "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/ec67/hdl" "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/86fe/hdl" "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/f0b6/hdl/verilog" "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/0127/hdl/verilog" "+incdir+C:/Xilinx/Vivado/2024.2/data/xilinx_vip/include" -l xilinx_vip -l xpm -l axi_infrastructure_v1_1_0 -l axi_vip_v1_1_19 -l processing_system7_vip_v1_0_21 -l xil_defaultlib -l xlconstant_v1_1_9 -l lib_cdc_v1_0_3 -l proc_sys_reset_v5_0_16 -l smartconnect_v1_0 -l axi_register_slice_v2_1_33 \
"C:/Xilinx/Vivado/2024.2/data/ip/xpm/xpm_fifo/hdl/xpm_fifo.sv" \
"C:/Xilinx/Vivado/2024.2/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv" \
"C:/Xilinx/Vivado/2024.2/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \

vcom -work xpm -93  \
"C:/Xilinx/Vivado/2024.2/data/ip/xpm/xpm_VCOMP.vhd" \

vlog -work axi_infrastructure_v1_1_0  -v2k5 "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/ec67/hdl" "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/86fe/hdl" "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/f0b6/hdl/verilog" "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/0127/hdl/verilog" "+incdir+C:/Xilinx/Vivado/2024.2/data/xilinx_vip/include" -l xilinx_vip -l xpm -l axi_infrastructure_v1_1_0 -l axi_vip_v1_1_19 -l processing_system7_vip_v1_0_21 -l xil_defaultlib -l xlconstant_v1_1_9 -l lib_cdc_v1_0_3 -l proc_sys_reset_v5_0_16 -l smartconnect_v1_0 -l axi_register_slice_v2_1_33 \
"../../../../Transformer.gen/sources_1/bd/design_1/ipshared/ec67/hdl/axi_infrastructure_v1_1_vl_rfs.v" \

vlog -work axi_vip_v1_1_19  -sv2k12 "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/ec67/hdl" "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/86fe/hdl" "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/f0b6/hdl/verilog" "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/0127/hdl/verilog" "+incdir+C:/Xilinx/Vivado/2024.2/data/xilinx_vip/include" -l xilinx_vip -l xpm -l axi_infrastructure_v1_1_0 -l axi_vip_v1_1_19 -l processing_system7_vip_v1_0_21 -l xil_defaultlib -l xlconstant_v1_1_9 -l lib_cdc_v1_0_3 -l proc_sys_reset_v5_0_16 -l smartconnect_v1_0 -l axi_register_slice_v2_1_33 \
"../../../../Transformer.gen/sources_1/bd/design_1/ipshared/8c45/hdl/axi_vip_v1_1_vl_rfs.sv" \

vlog -work processing_system7_vip_v1_0_21  -sv2k12 "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/ec67/hdl" "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/86fe/hdl" "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/f0b6/hdl/verilog" "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/0127/hdl/verilog" "+incdir+C:/Xilinx/Vivado/2024.2/data/xilinx_vip/include" -l xilinx_vip -l xpm -l axi_infrastructure_v1_1_0 -l axi_vip_v1_1_19 -l processing_system7_vip_v1_0_21 -l xil_defaultlib -l xlconstant_v1_1_9 -l lib_cdc_v1_0_3 -l proc_sys_reset_v5_0_16 -l smartconnect_v1_0 -l axi_register_slice_v2_1_33 \
"../../../../Transformer.gen/sources_1/bd/design_1/ipshared/86fe/hdl/processing_system7_vip_v1_0_vl_rfs.sv" \

vlog -work xil_defaultlib  -v2k5 "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/ec67/hdl" "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/86fe/hdl" "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/f0b6/hdl/verilog" "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/0127/hdl/verilog" "+incdir+C:/Xilinx/Vivado/2024.2/data/xilinx_vip/include" -l xilinx_vip -l xpm -l axi_infrastructure_v1_1_0 -l axi_vip_v1_1_19 -l processing_system7_vip_v1_0_21 -l xil_defaultlib -l xlconstant_v1_1_9 -l lib_cdc_v1_0_3 -l proc_sys_reset_v5_0_16 -l smartconnect_v1_0 -l axi_register_slice_v2_1_33 \
"../../../bd/design_1/ip/design_1_processing_system7_0_2/sim/design_1_processing_system7_0_2.v" \

vcom -work xil_defaultlib -93  \
"../../../bd/design_1/ipshared/7e01/hdl/transformer_axi_slave_lite_v1_0_S00_AXI.vhd" \
"../../../bd/design_1/ipshared/7e01/hdl/transformer_axi.vhd" \
"../../../bd/design_1/ip/design_1_transformer_axi_0_2/sim/design_1_transformer_axi_0_2.vhd" \

vlog -work xil_defaultlib  -v2k5 "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/ec67/hdl" "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/86fe/hdl" "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/f0b6/hdl/verilog" "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/0127/hdl/verilog" "+incdir+C:/Xilinx/Vivado/2024.2/data/xilinx_vip/include" -l xilinx_vip -l xpm -l axi_infrastructure_v1_1_0 -l axi_vip_v1_1_19 -l processing_system7_vip_v1_0_21 -l xil_defaultlib -l xlconstant_v1_1_9 -l lib_cdc_v1_0_3 -l proc_sys_reset_v5_0_16 -l smartconnect_v1_0 -l axi_register_slice_v2_1_33 \
"../../../bd/design_1/ip/design_1_axi_smc_2/bd_0/sim/bd_6e42.v" \

vlog -work xlconstant_v1_1_9  -v2k5 "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/ec67/hdl" "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/86fe/hdl" "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/f0b6/hdl/verilog" "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/0127/hdl/verilog" "+incdir+C:/Xilinx/Vivado/2024.2/data/xilinx_vip/include" -l xilinx_vip -l xpm -l axi_infrastructure_v1_1_0 -l axi_vip_v1_1_19 -l processing_system7_vip_v1_0_21 -l xil_defaultlib -l xlconstant_v1_1_9 -l lib_cdc_v1_0_3 -l proc_sys_reset_v5_0_16 -l smartconnect_v1_0 -l axi_register_slice_v2_1_33 \
"../../../../Transformer.gen/sources_1/bd/design_1/ipshared/e2d2/hdl/xlconstant_v1_1_vl_rfs.v" \

vlog -work xil_defaultlib  -v2k5 "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/ec67/hdl" "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/86fe/hdl" "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/f0b6/hdl/verilog" "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/0127/hdl/verilog" "+incdir+C:/Xilinx/Vivado/2024.2/data/xilinx_vip/include" -l xilinx_vip -l xpm -l axi_infrastructure_v1_1_0 -l axi_vip_v1_1_19 -l processing_system7_vip_v1_0_21 -l xil_defaultlib -l xlconstant_v1_1_9 -l lib_cdc_v1_0_3 -l proc_sys_reset_v5_0_16 -l smartconnect_v1_0 -l axi_register_slice_v2_1_33 \
"../../../bd/design_1/ip/design_1_axi_smc_2/bd_0/ip/ip_0/sim/bd_6e42_one_0.v" \

vcom -work lib_cdc_v1_0_3 -93  \
"../../../../Transformer.gen/sources_1/bd/design_1/ipshared/2a4f/hdl/lib_cdc_v1_0_rfs.vhd" \

vcom -work proc_sys_reset_v5_0_16 -93  \
"../../../../Transformer.gen/sources_1/bd/design_1/ipshared/0831/hdl/proc_sys_reset_v5_0_vh_rfs.vhd" \

vcom -work xil_defaultlib -93  \
"../../../bd/design_1/ip/design_1_axi_smc_2/bd_0/ip/ip_1/sim/bd_6e42_psr_aclk_0.vhd" \

vlog -work smartconnect_v1_0  -sv2k12 "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/ec67/hdl" "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/86fe/hdl" "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/f0b6/hdl/verilog" "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/0127/hdl/verilog" "+incdir+C:/Xilinx/Vivado/2024.2/data/xilinx_vip/include" -l xilinx_vip -l xpm -l axi_infrastructure_v1_1_0 -l axi_vip_v1_1_19 -l processing_system7_vip_v1_0_21 -l xil_defaultlib -l xlconstant_v1_1_9 -l lib_cdc_v1_0_3 -l proc_sys_reset_v5_0_16 -l smartconnect_v1_0 -l axi_register_slice_v2_1_33 \
"../../../../Transformer.gen/sources_1/bd/design_1/ipshared/f0b6/hdl/sc_util_v1_0_vl_rfs.sv" \
"../../../../Transformer.gen/sources_1/bd/design_1/ipshared/f49a/hdl/sc_mmu_v1_0_vl_rfs.sv" \

vlog -work xil_defaultlib  -sv2k12 "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/ec67/hdl" "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/86fe/hdl" "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/f0b6/hdl/verilog" "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/0127/hdl/verilog" "+incdir+C:/Xilinx/Vivado/2024.2/data/xilinx_vip/include" -l xilinx_vip -l xpm -l axi_infrastructure_v1_1_0 -l axi_vip_v1_1_19 -l processing_system7_vip_v1_0_21 -l xil_defaultlib -l xlconstant_v1_1_9 -l lib_cdc_v1_0_3 -l proc_sys_reset_v5_0_16 -l smartconnect_v1_0 -l axi_register_slice_v2_1_33 \
"../../../bd/design_1/ip/design_1_axi_smc_2/bd_0/ip/ip_2/sim/bd_6e42_s00mmu_0.sv" \

vlog -work smartconnect_v1_0  -sv2k12 "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/ec67/hdl" "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/86fe/hdl" "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/f0b6/hdl/verilog" "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/0127/hdl/verilog" "+incdir+C:/Xilinx/Vivado/2024.2/data/xilinx_vip/include" -l xilinx_vip -l xpm -l axi_infrastructure_v1_1_0 -l axi_vip_v1_1_19 -l processing_system7_vip_v1_0_21 -l xil_defaultlib -l xlconstant_v1_1_9 -l lib_cdc_v1_0_3 -l proc_sys_reset_v5_0_16 -l smartconnect_v1_0 -l axi_register_slice_v2_1_33 \
"../../../../Transformer.gen/sources_1/bd/design_1/ipshared/2da8/hdl/sc_transaction_regulator_v1_0_vl_rfs.sv" \

vlog -work xil_defaultlib  -sv2k12 "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/ec67/hdl" "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/86fe/hdl" "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/f0b6/hdl/verilog" "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/0127/hdl/verilog" "+incdir+C:/Xilinx/Vivado/2024.2/data/xilinx_vip/include" -l xilinx_vip -l xpm -l axi_infrastructure_v1_1_0 -l axi_vip_v1_1_19 -l processing_system7_vip_v1_0_21 -l xil_defaultlib -l xlconstant_v1_1_9 -l lib_cdc_v1_0_3 -l proc_sys_reset_v5_0_16 -l smartconnect_v1_0 -l axi_register_slice_v2_1_33 \
"../../../bd/design_1/ip/design_1_axi_smc_2/bd_0/ip/ip_3/sim/bd_6e42_s00tr_0.sv" \

vlog -work smartconnect_v1_0  -sv2k12 "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/ec67/hdl" "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/86fe/hdl" "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/f0b6/hdl/verilog" "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/0127/hdl/verilog" "+incdir+C:/Xilinx/Vivado/2024.2/data/xilinx_vip/include" -l xilinx_vip -l xpm -l axi_infrastructure_v1_1_0 -l axi_vip_v1_1_19 -l processing_system7_vip_v1_0_21 -l xil_defaultlib -l xlconstant_v1_1_9 -l lib_cdc_v1_0_3 -l proc_sys_reset_v5_0_16 -l smartconnect_v1_0 -l axi_register_slice_v2_1_33 \
"../../../../Transformer.gen/sources_1/bd/design_1/ipshared/63ed/hdl/sc_si_converter_v1_0_vl_rfs.sv" \

vlog -work xil_defaultlib  -sv2k12 "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/ec67/hdl" "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/86fe/hdl" "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/f0b6/hdl/verilog" "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/0127/hdl/verilog" "+incdir+C:/Xilinx/Vivado/2024.2/data/xilinx_vip/include" -l xilinx_vip -l xpm -l axi_infrastructure_v1_1_0 -l axi_vip_v1_1_19 -l processing_system7_vip_v1_0_21 -l xil_defaultlib -l xlconstant_v1_1_9 -l lib_cdc_v1_0_3 -l proc_sys_reset_v5_0_16 -l smartconnect_v1_0 -l axi_register_slice_v2_1_33 \
"../../../bd/design_1/ip/design_1_axi_smc_2/bd_0/ip/ip_4/sim/bd_6e42_s00sic_0.sv" \

vlog -work smartconnect_v1_0  -sv2k12 "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/ec67/hdl" "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/86fe/hdl" "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/f0b6/hdl/verilog" "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/0127/hdl/verilog" "+incdir+C:/Xilinx/Vivado/2024.2/data/xilinx_vip/include" -l xilinx_vip -l xpm -l axi_infrastructure_v1_1_0 -l axi_vip_v1_1_19 -l processing_system7_vip_v1_0_21 -l xil_defaultlib -l xlconstant_v1_1_9 -l lib_cdc_v1_0_3 -l proc_sys_reset_v5_0_16 -l smartconnect_v1_0 -l axi_register_slice_v2_1_33 \
"../../../../Transformer.gen/sources_1/bd/design_1/ipshared/cef3/hdl/sc_axi2sc_v1_0_vl_rfs.sv" \

vlog -work xil_defaultlib  -sv2k12 "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/ec67/hdl" "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/86fe/hdl" "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/f0b6/hdl/verilog" "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/0127/hdl/verilog" "+incdir+C:/Xilinx/Vivado/2024.2/data/xilinx_vip/include" -l xilinx_vip -l xpm -l axi_infrastructure_v1_1_0 -l axi_vip_v1_1_19 -l processing_system7_vip_v1_0_21 -l xil_defaultlib -l xlconstant_v1_1_9 -l lib_cdc_v1_0_3 -l proc_sys_reset_v5_0_16 -l smartconnect_v1_0 -l axi_register_slice_v2_1_33 \
"../../../bd/design_1/ip/design_1_axi_smc_2/bd_0/ip/ip_5/sim/bd_6e42_s00a2s_0.sv" \

vlog -work smartconnect_v1_0  -sv2k12 "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/ec67/hdl" "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/86fe/hdl" "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/f0b6/hdl/verilog" "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/0127/hdl/verilog" "+incdir+C:/Xilinx/Vivado/2024.2/data/xilinx_vip/include" -l xilinx_vip -l xpm -l axi_infrastructure_v1_1_0 -l axi_vip_v1_1_19 -l processing_system7_vip_v1_0_21 -l xil_defaultlib -l xlconstant_v1_1_9 -l lib_cdc_v1_0_3 -l proc_sys_reset_v5_0_16 -l smartconnect_v1_0 -l axi_register_slice_v2_1_33 \
"../../../../Transformer.gen/sources_1/bd/design_1/ipshared/0127/hdl/sc_node_v1_0_vl_rfs.sv" \

vlog -work xil_defaultlib  -sv2k12 "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/ec67/hdl" "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/86fe/hdl" "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/f0b6/hdl/verilog" "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/0127/hdl/verilog" "+incdir+C:/Xilinx/Vivado/2024.2/data/xilinx_vip/include" -l xilinx_vip -l xpm -l axi_infrastructure_v1_1_0 -l axi_vip_v1_1_19 -l processing_system7_vip_v1_0_21 -l xil_defaultlib -l xlconstant_v1_1_9 -l lib_cdc_v1_0_3 -l proc_sys_reset_v5_0_16 -l smartconnect_v1_0 -l axi_register_slice_v2_1_33 \
"../../../bd/design_1/ip/design_1_axi_smc_2/bd_0/ip/ip_6/sim/bd_6e42_sarn_0.sv" \
"../../../bd/design_1/ip/design_1_axi_smc_2/bd_0/ip/ip_7/sim/bd_6e42_srn_0.sv" \
"../../../bd/design_1/ip/design_1_axi_smc_2/bd_0/ip/ip_8/sim/bd_6e42_sawn_0.sv" \
"../../../bd/design_1/ip/design_1_axi_smc_2/bd_0/ip/ip_9/sim/bd_6e42_swn_0.sv" \
"../../../bd/design_1/ip/design_1_axi_smc_2/bd_0/ip/ip_10/sim/bd_6e42_sbn_0.sv" \

vlog -work smartconnect_v1_0  -sv2k12 "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/ec67/hdl" "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/86fe/hdl" "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/f0b6/hdl/verilog" "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/0127/hdl/verilog" "+incdir+C:/Xilinx/Vivado/2024.2/data/xilinx_vip/include" -l xilinx_vip -l xpm -l axi_infrastructure_v1_1_0 -l axi_vip_v1_1_19 -l processing_system7_vip_v1_0_21 -l xil_defaultlib -l xlconstant_v1_1_9 -l lib_cdc_v1_0_3 -l proc_sys_reset_v5_0_16 -l smartconnect_v1_0 -l axi_register_slice_v2_1_33 \
"../../../../Transformer.gen/sources_1/bd/design_1/ipshared/7f4f/hdl/sc_sc2axi_v1_0_vl_rfs.sv" \

vlog -work xil_defaultlib  -sv2k12 "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/ec67/hdl" "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/86fe/hdl" "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/f0b6/hdl/verilog" "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/0127/hdl/verilog" "+incdir+C:/Xilinx/Vivado/2024.2/data/xilinx_vip/include" -l xilinx_vip -l xpm -l axi_infrastructure_v1_1_0 -l axi_vip_v1_1_19 -l processing_system7_vip_v1_0_21 -l xil_defaultlib -l xlconstant_v1_1_9 -l lib_cdc_v1_0_3 -l proc_sys_reset_v5_0_16 -l smartconnect_v1_0 -l axi_register_slice_v2_1_33 \
"../../../bd/design_1/ip/design_1_axi_smc_2/bd_0/ip/ip_11/sim/bd_6e42_m00s2a_0.sv" \

vlog -work smartconnect_v1_0  -sv2k12 "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/ec67/hdl" "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/86fe/hdl" "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/f0b6/hdl/verilog" "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/0127/hdl/verilog" "+incdir+C:/Xilinx/Vivado/2024.2/data/xilinx_vip/include" -l xilinx_vip -l xpm -l axi_infrastructure_v1_1_0 -l axi_vip_v1_1_19 -l processing_system7_vip_v1_0_21 -l xil_defaultlib -l xlconstant_v1_1_9 -l lib_cdc_v1_0_3 -l proc_sys_reset_v5_0_16 -l smartconnect_v1_0 -l axi_register_slice_v2_1_33 \
"../../../../Transformer.gen/sources_1/bd/design_1/ipshared/37bc/hdl/sc_exit_v1_0_vl_rfs.sv" \

vlog -work xil_defaultlib  -sv2k12 "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/ec67/hdl" "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/86fe/hdl" "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/f0b6/hdl/verilog" "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/0127/hdl/verilog" "+incdir+C:/Xilinx/Vivado/2024.2/data/xilinx_vip/include" -l xilinx_vip -l xpm -l axi_infrastructure_v1_1_0 -l axi_vip_v1_1_19 -l processing_system7_vip_v1_0_21 -l xil_defaultlib -l xlconstant_v1_1_9 -l lib_cdc_v1_0_3 -l proc_sys_reset_v5_0_16 -l smartconnect_v1_0 -l axi_register_slice_v2_1_33 \
"../../../bd/design_1/ip/design_1_axi_smc_2/bd_0/ip/ip_12/sim/bd_6e42_m00e_0.sv" \

vlog -work smartconnect_v1_0  -sv2k12 "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/ec67/hdl" "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/86fe/hdl" "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/f0b6/hdl/verilog" "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/0127/hdl/verilog" "+incdir+C:/Xilinx/Vivado/2024.2/data/xilinx_vip/include" -l xilinx_vip -l xpm -l axi_infrastructure_v1_1_0 -l axi_vip_v1_1_19 -l processing_system7_vip_v1_0_21 -l xil_defaultlib -l xlconstant_v1_1_9 -l lib_cdc_v1_0_3 -l proc_sys_reset_v5_0_16 -l smartconnect_v1_0 -l axi_register_slice_v2_1_33 \
"../../../../Transformer.gen/sources_1/bd/design_1/ipshared/3718/hdl/sc_switchboard_v1_0_vl_rfs.sv" \

vlog -work axi_register_slice_v2_1_33  -v2k5 "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/ec67/hdl" "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/86fe/hdl" "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/f0b6/hdl/verilog" "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/0127/hdl/verilog" "+incdir+C:/Xilinx/Vivado/2024.2/data/xilinx_vip/include" -l xilinx_vip -l xpm -l axi_infrastructure_v1_1_0 -l axi_vip_v1_1_19 -l processing_system7_vip_v1_0_21 -l xil_defaultlib -l xlconstant_v1_1_9 -l lib_cdc_v1_0_3 -l proc_sys_reset_v5_0_16 -l smartconnect_v1_0 -l axi_register_slice_v2_1_33 \
"../../../../Transformer.gen/sources_1/bd/design_1/ipshared/3ee4/hdl/axi_register_slice_v2_1_vl_rfs.v" \

vlog -work xil_defaultlib  -v2k5 "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/ec67/hdl" "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/86fe/hdl" "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/f0b6/hdl/verilog" "+incdir+../../../../Transformer.gen/sources_1/bd/design_1/ipshared/0127/hdl/verilog" "+incdir+C:/Xilinx/Vivado/2024.2/data/xilinx_vip/include" -l xilinx_vip -l xpm -l axi_infrastructure_v1_1_0 -l axi_vip_v1_1_19 -l processing_system7_vip_v1_0_21 -l xil_defaultlib -l xlconstant_v1_1_9 -l lib_cdc_v1_0_3 -l proc_sys_reset_v5_0_16 -l smartconnect_v1_0 -l axi_register_slice_v2_1_33 \
"../../../bd/design_1/ip/design_1_axi_smc_2/sim/design_1_axi_smc_2.v" \

vcom -work xil_defaultlib -93  \
"../../../bd/design_1/ip/design_1_rst_ps7_0_100M_2/sim/design_1_rst_ps7_0_100M_2.vhd" \
"../../../bd/design_1/sim/design_1.vhd" \

vlog -work xil_defaultlib \
"glbl.v"

