// Copyright (C) 2019 Toitware ApS. All rights reserved.
import binary
import modules.i2c show *
import gpio


Si7006_ADDR                             :=0x40 // default device address
//Si7006 register addresses
Si7006_MEAS_REL_HUMIDITY_MASTER_MODE    :=0xE5
Si7006_MEAS_REL_HUMIDITY_NO_MASTER_MODE :=0xF5
Si7006_MEAS_TEMP_MASTER_MODE            :=0xE3
Si7006_MEAS_TEMP_NO_MASTER_MODE         :=0xF3
Si7006_READ_OLD_TEMP                    :=0xE0
Si7006_RESET 							              :=0xFE
Si7006_WRITE_HUMIDITY_TEMP_CONTR		    :=0xE6						
Si7006_READ_HUMIDITY_TEMP_CONTR 	    	:=0xE7
Si7006_WRITE_HEATER_CONTR				        :=0x51
Si7006_READ_HEATER_CONTR			        	:=0x11
Si7006_READ_ID_LOW_0					          :=0xFA
Si7006_READ_ID_LOW_1					          :=0x0F
Si7006_READ_ID_HIGH_0				          	:=0xFC
Si7006_READ_ID_HIGH_1					          :=0xC9
Si7006_FIRMWARE_0						            :=0x84
Si7006_FIRMWARE_1						            :=0xB8

modes := [Si7006_MEAS_REL_HUMIDITY_MASTER_MODE, Si7006_MEAS_REL_HUMIDITY_NO_MASTER_MODE, Si7006_MEAS_TEMP_MASTER_MODE, Si7006_MEAS_TEMP_NO_MASTER_MODE, Si7006_READ_OLD_TEMP, Si7006_RESET, Si7006_WRITE_HUMIDITY_TEMP_CONTR, Si7006_READ_HUMIDITY_TEMP_CONTR, Si7006_WRITE_HEATER_CONTR, Si7006_READ_HEATER_CONTR, Si7006_READ_ID_LOW_0, Si7006_READ_ID_LOW_1, Si7006_READ_ID_HIGH_0, Si7006_READ_ID_HIGH_1, Si7006_FIRMWARE_0, Si7006_FIRMWARE_1]

class SI7006A20:
  device_ := null

  SI7006A20 .device_:
  
  // Read 32 bytes from a given register and return a byte array
  register_read address mode-> ByteArray:
    n_bytes_to_read := 20
    command_array := ByteArray 2

    command_array[0] =  address          // Header byte
    command_array[1] = mode //Si7006_MEAS_TEMP_NO_MASTER_MODE            // Number of bytes in frame

    log "command array single address"
    log command_array
    device_.write command_array       // Execute command
    return device_.read_reg address n_bytes_to_read // Return bytes

main:
  // Set pins for connection to device
  i2c := I2C
    400_000
    gpio.Pin 17
    gpio.Pin 16
  
  // Set relay for measuring
  relay := gpio.Pin 2
  relay.configure gpio.OUTPUT_CONF
  relay.set 0
  sleep 3000

  // Connect device
  device := i2c.connect Si7006_ADDR

  sleep(1)
  // Read output registers
  si7006a20 := SI7006A20 device

  
  
  for j:=0; j<256; j++:
    bytes_si7006 := si7006a20.register_read Si7006_ADDR j
    log bytes_si7006
    sleep (10)
  relay.set 0