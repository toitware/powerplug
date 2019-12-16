// Copyright (C) 2019 Toitware ApS. All rights reserved.
import binary
import i2c
import gpio
import serial

RESET ::= 0xFE
READ_TEMPERATURE ::= 0xF3
READ_HUMIDITY ::= 0xF5

class SI7006A20:
  device_ := null
  t_calib_coef := null // calibration coefficient for exponential approximation of temperature change in the chip

  SI7006A20 .device_:
    this.reset_
    t_calib_coef = 1

  // Read last temperature measurement
  read_temperature -> float:
    commands := ByteArray 1
    commands[0] = READ_TEMPERATURE
    device_.write commands
    sleep 20
    temp_response := device_.read 2
    temperature_measured := (175.72 * (temp_response[0] * 256.0 + temp_response[1]) / 65536.0) - 46.85
    t_calib_coef = 0.8*t_calib_coef
    temperature := temperature_measured - 12.05 + t_calib_coef
    return temperature

  // Read last humidity measurement
  read_humidity -> float:
    commands := ByteArray 1
    commands[0] = READ_HUMIDITY
    device_.write commands
    sleep 20
    hum_response := device_.read 2
    humidity := (125.0 * (hum_response[0] * 256.0 + hum_response[1]) / 65536.0) - 6.0	    
    return humidity
  
  // Reset measurements
  reset_ -> none:
    commands := ByteArray 1
    commands[0] = RESET
    device_.write commands
    sleep 150