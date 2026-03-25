# 2026-03-16T12:23:59.378528700
import vitis

client = vitis.create_client()
client.set_workspace(path="vitis_workspace")

platform = client.get_component(name="transformer_platform")
status = platform.update_hw(hw_design = "$COMPONENT_LOCATION/../../FPGA/Transformer/Transformer/top_level.xsa")

vitis.dispose()

