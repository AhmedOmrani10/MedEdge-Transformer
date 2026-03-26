# 2026-03-26T13:47:34.427935300
import vitis

client = vitis.create_client()
client.set_workspace(path="vitis_workspace")

platform = client.get_component(name="transformer_platform")
status = platform.build()

comp = client.get_component(name="transformer_app")
comp.build()

vitis.dispose()

