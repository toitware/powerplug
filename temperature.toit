// Copyright (C) 2019 Toitware ApS. All rights reserved.
import binary
import i2c
import gpio
import serial
import metrics

class SI7006A20:
  device_ := null

  // TODO: Add default connection to 0x40
  SI7006A20 .device_:
    
  read_temperature -> none:
    commands := ByteArray 1
    commands[0] = 0xF3
    device_.write commands
    sleep 25
    temp_response := device_.read 2
    temperature := (175.72 * (temp_response[0] * 256.0 + temp_response[1]) / 65536.0) - 46.85
    metrics.gauge "powerswitch_temperature" temperature
    log "Temperature is $(%3.2f (temperature) ) [C]"

  read_humidity -> none:
    commands := ByteArray 1
    commands[0] = 0xF5
    device_.write commands
    sleep 25
    hum_response := device_.read 2
    humidity := (125.0 * (hum_response[0] * 256.0 + hum_response[1]) / 65536.0) - 6.0	    
    metrics.gauge "powerswitch_humidity" humidity
    log "Humidity is $(%3.5f (humidity) ) [%]"
  
  reset_ -> none:
    commands := ByteArray 1
    commands[0] = 0xFE
    device_.write commands
    sleep 150
