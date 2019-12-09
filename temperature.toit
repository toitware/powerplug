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
    
  read_temperature -> Float:
    commands := ByteArray 1
    commands[0] = 0xF3
    device_.write commands
    sleep 25
    temp_response := device_.read 2
    cTemp := (175.72 * (temp_response[0] * 256.0 + temp_response[1]) / 65536.0) - 46.85
    return cTemp

  read_humidity -> Float:
    commands := ByteArray 1
    commands[0] = 0xF5
    device_.write commands
    sleep 25
    hum_response := device_.read 2
    humidity := (125.0 * (hum_response[0] * 256.0 + hum_response[1]) / 65536.0) - 6.0	    
    return humidity
  
  reset_ -> none:
    commands := ByteArray 1
    commands[0] = 0xFE
    device_.write commands
    sleep 150

main:
  // Set pins for connection to device
  i2c := i2c.I2C
    400_000
    gpio.Pin 17
    gpio.Pin 16
  

  // Set relay for measuring
  relay := gpio.Pin 2
  relay.configure gpio.OUTPUT_CONF
  relay.set 1
  sleep 1000

  si7006a20 := SI7006A20 (i2c.connect 0x40)
  si7006a20.reset_

  i := 0
  while i < 10:
    log "logging metrics"
    metrics.gauge "powerswitch_humidity" si7006a20.read_humidity
    metrics.gauge "powerswitch_temperature" si7006a20.read_temperature
    i += 1

  relay.set 0