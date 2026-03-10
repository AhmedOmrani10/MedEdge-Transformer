# 2026-03-09T22:51:39.808846600
import vitis

client = vitis.create_client()
client.set_workspace(path="vitis_workspace")

platform = client.create_platform_component(name = "transformer_platform",hw_design = "$COMPONENT_LOCATION/../../design_1_wrapper.xsa",os = "standalone",cpu = "ps7_cortexa9_0",domain_name = "standalone_ps7_cortexa9_0")

comp = client.create_app_component(name="transformer_app",platform = "$COMPONENT_LOCATION/../transformer_platform/export/transformer_platform/transformer_platform.xpfm",domain = "standalone_ps7_cortexa9_0")

platform = client.get_component(name="transformer_platform")
status = platform.build()

status = platform.update_hw(hw_design = "$COMPONENT_LOCATION/../../design_1_wrapper.xsa")

status = platform.build()

vitis.dispose()

