# 2026-03-05T17:13:23.463835100
import vitis

client = vitis.create_client()
client.set_workspace(path="uart_vitis")

vitis.dispose()

