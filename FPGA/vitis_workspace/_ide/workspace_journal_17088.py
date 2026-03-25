# 2026-03-24T15:33:10.799344900
import vitis

client = vitis.create_client()
client.set_workspace(path="vitis_workspace")

platform = client.get_component(name="transformer_platform")
status = platform.build()

comp = client.get_component(name="transformer_app")
comp.build()

status = platform.build()

comp.build()

vitis.dispose()

