# 2026-03-16T05:03:27.337221300
import vitis

client = vitis.create_client()
client.set_workspace(path="vitis_workspace")

platform = client.get_component(name="transformer_platform")
status = platform.update_hw(hw_design = "$COMPONENT_LOCATION/../../FPGA/Transformer/Transformer/top_level.xsa")

status = platform.build()

status = platform.build()

comp = client.get_component(name="transformer_app")
comp.build()

status = platform.update_hw(hw_design = "$COMPONENT_LOCATION/../../FPGA/Transformer/Transformer/top_level.xsa")

status = platform.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

status = platform.update_hw(hw_design = "$COMPONENT_LOCATION/../../FPGA/Transformer/Transformer/top_level.xsa")

status = platform.build()

status = platform.build()

comp.build()

status = platform.update_hw(hw_design = "$COMPONENT_LOCATION/../../FPGA/Transformer/Transformer/top_level.xsa")

status = platform.build()

status = platform.build()

comp.build()

status = platform.update_hw(hw_design = "$COMPONENT_LOCATION/../../FPGA/Transformer/Transformer/top_level.xsa")

status = platform.build()

status = platform.build()

comp.build()

