import vitis

client = vitis.create_client()
client.set_workspace(path=r"C:\vitis_timestamp_v3")

try:
    app = client.get_component(name="lwip_echo_server")
    print("STEP228_APP_BUILD_START", flush=True)
    result = app.build()
    print("STEP228_APP_BUILD_RESULT =", result, flush=True)
finally:
    client.close()
