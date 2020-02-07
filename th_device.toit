// Copyright (C) 2019 Toitware ApS. All rights reserved.
import binary
import i2c
import gpio
import serial
import math

RESET ::= 0xFE
READ_TEMPERATURE ::= 0xF3
READ_HUMIDITY ::= 0xF5

class SI7006A20:
  device_ := null
  calibration_base_ := null //Base of exponential function approximating heat characteristics. Depends on how fast the device reaches steady state.
  calibration_offset_transitional := null  //Offset that will exponentialy decrease in each iteration of measurement. Approximates the heating period of the device
  calibration_offset_static := null  //Steady offset representing difference between measured temp and real one when equilibrium is reached.
  sampling_time_ := null
  t_calib_coef_ := null

  SI7006A20 .device_ .sampling_time_ .calibration_offset_static .calibration_base_ .calibration_offset_transitional:
    this.reset_
    t_calib_coef_ = (math.pow calibration_base_ (sampling_time_/60000.0))

  // Read last temperature measurement
  read_temperature -> Map:
    commands := ByteArray 1
    commands[0] = READ_TEMPERATURE
    device_.write commands
    sleep --ms= 20
    temp_response := device_.read 2
    temperature_measured := (175.72 * (temp_response[0] * 256.0 + temp_response[1]) / 65536.0) - 46.85
    calibration_offset_transitional = calibration_offset_transitional * t_calib_coef_
    temperature_calibrated := temperature_measured + calibration_offset_transitional - calibration_offset_static
    return {"temperature_measured": temperature_measured, "temperature_calibrated": temperature_calibrated}

  // Read last humidity measurement
  read_humidity -> float:
    commands := ByteArray 1
    commands[0] = READ_HUMIDITY
    device_.write commands
    sleep --ms= 20
    hum_response := device_.read 2
    humidity := (125.0 * (hum_response[0] * 256.0 + hum_response[1]) / 65536.0) - 6.0	    
    return humidity
  
  // Reset measurements
  reset_ -> none:
    commands := ByteArray 1
    commands[0] = RESET
    device_.write commands
    sleep --ms= 150
