# Windows 11 Ethernet setup for Mercury XU5

This guide configures a dedicated, direct Ethernet connection between a Windows laptop and the Mercury XU5 FPGA board running the Timestamp V3 firmware.

## 1. Network configuration

Connect the laptop's Ethernet adapter directly to the board using an Ethernet cable.

| Parameter | Laptop Ethernet adapter | FPGA |
| --- | --- | --- |
| IPv4 address | `192.168.1.10` | `192.168.1.50` |
| Subnet mask | `255.255.255.0` | `255.255.255.0` |
| Prefix length | 24 | 24 |
| Default gateway | Leave blank | `192.168.1.1` (firmware setting) |
| DHCP | Disabled | Disabled |
| DNS | Leave blank | Not required for direct connection |
| UDP destination port | — | `5001` |

The laptop address is a recommended static address, not a firmware requirement. It must be unique on the connected network. The FPGA address and UDP port come from the [Vitis application](../Vitis/timestamp_v3_uart_off/lwip_echo_server/src/).

```text
Windows laptop                         Mercury XU5
192.168.1.10/24  <-- Ethernet cable -->  192.168.1.50/24
                                         UDP port 5001
```

## 2. Configure Ethernet in Windows 11

1. Press **Win + R**, type `ncpa.cpl`, and press Enter.
2. Identify the Ethernet adapter connected to the FPGA. Right-click it and select **Properties**.
3. Double-click **Internet Protocol Version 4 (TCP/IPv4)**.
4. Select **Use the following IP address** and enter:
   - IP address: `192.168.1.10`
   - Subnet mask: `255.255.255.0`
   - Default gateway: leave blank.
5. Leave the DNS server addresses blank for this dedicated connection.
6. Click **OK**, then **Close**.

Administrator privileges or authorization from the IT department may be required on a managed workstation. Do not modify the organization's security policies or unrelated network adapters.

## 3. Verify the configuration

Open PowerShell and run:

```powershell
Get-NetIPConfiguration
```

Confirm that the dedicated Ethernet adapter has IPv4 address `192.168.1.10`.

After the FPGA is running a known-good BOOT.BIN and the Ethernet link is up, test connectivity:

```powershell
ping 192.168.1.50
```

A successful ping confirms ICMP connectivity, not UDP application operation. If it fails, check the cable, link status, board boot state, and routing. Do not disable security controls to troubleshoot.

## 4. GUI configuration

Launch the [C++/Qt6 GUI](../GUI/cpp_qt6_realtime_v1/) after any required IT approval.

| Parameter | Value |
| --- | --- |
| Protocol | UDP |
| FPGA IP | `192.168.1.50` |
| FPGA port | `5001` |

Test command and telemetry communication separately from ping.

## 5. Important notes

- Keep the Wi-Fi configuration unchanged.
- If Wi-Fi or another adapter also uses `192.168.1.0/24`, routing conflicts may occur. Use a dedicated non-conflicting network or consult IT before changing network settings.
- Record the adapter's previous settings so they can be restored when reconnecting it to its usual network.
- Preserve the known-good boot image. A newly rebuilt BOOT.BIN must be hardware-validated before replacing it.
- This is a configuration guide, not evidence that a particular laptop or FPGA has passed a hardware connectivity test.
