# 2026-03-09T23:03:38.743394700
import vitis

client = vitis.create_client()
client.set_workspace(path="vitis_workspace")

platform = client.get_component(name="transformer_platform")
status = platform.build()

comp = client.get_component(name="transformer_app")
comp.build()

status = platform.build()

status = platform.build()

status = platform.build()

status = platform.build()

platform = client.get_component(name="transformer_platform")
status = platform.build()

comp = client.get_component(name="transformer_app")
comp.build()

status = platform.update_hw(hw_design = "$COMPONENT_LOCATION/../../FPGA/Transformer/design_1_wrapper.xsa")

status = platform.build()

vitis.dispose()

