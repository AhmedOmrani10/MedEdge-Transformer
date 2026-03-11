# 2026-03-11T14:51:25.940390800
import vitis

client = vitis.create_client()
client.set_workspace(path="vitis_workspace")

platform = client.get_component(name="transformer_platform")
status = platform.update_hw(hw_design = "$COMPONENT_LOCATION/../../FPGA/Transformer/design_1_wrapper.xsa")

status = platform.build()

comp = client.get_component(name="transformer_app")
comp.build()

status = platform.build()

status = platform.build()

comp.build()

vitis.dispose()

