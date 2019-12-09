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
    
  read_temperature -> ByteArray:
    commands := ByteArray 1
    commands[0] = 0xF3
    device_.write commands
    sleep 25
    return device_.read 2

  read_humidity -> ByteArray:
    commands := ByteArray 1
    commands[0] = 0xF5
    device_.write commands
    sleep 25
    return device_.read 2
  
  reset_:
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
    bytes_si7006_hum := si7006a20.read_humidity
    log bytes_si7006_hum
    //humidity := ((125.0 * ((bytes_si7006_hum[0] * 256.0) + bytes_si7006_hum[1])) / 65536.0) - 6.0
    humidity := (125.0 * (bytes_si7006_hum[0] * 256.0 + bytes_si7006_hum[1]) / 65536.0) - 6.0	    
    log "Humidity is $(%3.5f (humidity) ) [%]"

    metrics.gauge "powerswitch_humidity" (humidity as Float)
    
    sleep 100

    bytes_si7006_temp := si7006a20.read_temperature
    log bytes_si7006_temp

    cTemp := (175.72 * (bytes_si7006_temp[0] * 256.0 + bytes_si7006_temp[1]) / 65536.0) - 46.85
    log "Temperature is $(%3.2f (cTemp) ) [C]"

    fTemp := cTemp * 1.8 + 32
    log "Temperature is $(%3.2f (fTemp) ) [F]"
    i += 1
  
  relay.set 0