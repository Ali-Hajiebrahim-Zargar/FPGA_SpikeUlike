import vitis

client = vitis.create_client()
client.set_workspace(path=r"C:\vitis_timestamp_v3")

platform = client.get_component(name="platform")

print("STEP228_PLATFORM_BUILD_START", flush=True)
result = platform.build()
print("STEP228_PLATFORM_BUILD_RESULT =", result, flush=True)

client.close()
