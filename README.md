# powerplug

// Copyright (C) 2019 Toitware ApS. All rights reserved.

Power Switch includes ESP32-WROOM-32D chip with running Toit system, MCP39F521 energy measurment unit and si7006-a20 unit for temperature and humidity measurements.

In order to set up new device:

1. Make sure you have up-to-date toit software installed on your computer. Console commands:
  toit doctor
  toit update
  toit sdk update

2. If the device is not falshed then open it. Plug in the connector and use USB port on your PC. Then console command:
  toit serial flash -p wifi.ssid=<your_network_name> -p wifi.password=<your_wifi_passwor> -p broker.host=<Host IP>

3. Switch to remote context      
  toit context default remote
4. Choose the default device
  toit device default <device_name>

5. Deploy button control job    
  toit device deploy button_deploy.yaml

6. Deploy measurement file      
  toit device deploy measurement.yaml

Files included in the code:
button_deploy.yaml
button.toit
energy_device.toit
measurement.yaml
power_plug_main.toit
README.md
th_device.toit
