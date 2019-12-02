// Copyright (C) 2019 Toitware ApS. All rights reserved.
import binary
import i2c
import gpio
import serial


Si7006_ADDR                             :=0x40 // default device address
//Si7006 register addresses
Si7006_MEAS_REL_HUMIDITY_MASTER_MODE    :=0xE5  //229
Si7006_MEAS_REL_HUMIDITY_NO_MASTER_MODE :=0xF5  //245
Si7006_MEAS_TEMP_MASTER_MODE            :=0xE3  //227
Si7006_MEAS_TEMP_NO_MASTER_MODE         :=0xF3  //243
Si7006_READ_OLD_TEMP                    :=0xE0 //224
Si7006_RESET 							              :=0xFE //254
Si7006_WRITE_HUMIDITY_TEMP_CONTR		    :=0xE6	//230					
Si7006_READ_HUMIDITY_TEMP_CONTR 	    	:=0xE7 //231
Si7006_WRITE_HEATER_CONTR				        :=0x51 //81
Si7006_READ_HEATER_CONTR			        	:=0x11 //17
Si7006_READ_ID_LOW_0					          :=0xFA  //250
Si7006_READ_ID_LOW_1					          :=0x0F //15
Si7006_READ_ID_HIGH_0				          	:=0xFC  //252
Si7006_READ_ID_HIGH_1					          :=0xC9  //201
Si7006_FIRMWARE_0						            :=0x84  //132
Si7006_FIRMWARE_1						            :=0xB8  //184

modes := [Si7006_MEAS_REL_HUMIDITY_MASTER_MODE, Si7006_MEAS_REL_HUMIDITY_NO_MASTER_MODE, Si7006_MEAS_TEMP_MASTER_MODE, Si7006_MEAS_TEMP_NO_MASTER_MODE, Si7006_READ_OLD_TEMP, Si7006_RESET, Si7006_WRITE_HUMIDITY_TEMP_CONTR, Si7006_READ_HUMIDITY_TEMP_CONTR, Si7006_WRITE_HEATER_CONTR, Si7006_READ_HEATER_CONTR, Si7006_READ_ID_LOW_0, Si7006_READ_ID_LOW_1, Si7006_READ_ID_HIGH_0, Si7006_READ_ID_HIGH_1, Si7006_FIRMWARE_0, Si7006_FIRMWARE_1]

class SI7006A20:
  device_ := null

  SI7006A20 .device_:
  
  // Read 32 bytes from a given register and return a byte array
  register_read address mode-> ByteArray:
    n_bytes_to_read := 10
    command_array := ByteArray 2

    command_array[0] =  address          // Header byte
    command_array[1] = mode //Si7006_MEAS_TEMP_NO_MASTER_MODE            // Number of bytes in frame

    log "command array single address"
    log command_array
    //device_.write_bytes command_array      // Execute command
    return device_.read_bytes mode n_bytes_to_read // Return bytes*/

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
  sleep 3000

  // Connect device
  device := serial.I2CRegisters
    i2c.connect Si7006_ADDR
  log "device connected"
 

  sleep(1)
  // Read output registers
  si7006a20 := SI7006A20 device
  log "Read output registers"

  /* Stopped working at some point
  //Humidity
  bytes_si7006_hum := si7006a20.register_read Si7006_ADDR Si7006_MEAS_REL_HUMIDITY_NO_MASTER_MODE //modes[3]
  log bytes_si7006_hum
  sleep (10)
   //Convert the data
  humidity := (125.0 * (bytes_si7006_hum[0] * 256.0 + bytes_si7006_hum[1]) / 65536.0) - 6.0
  log humidity
  */

//Temperature
  bytes_si7006_temp := si7006a20.register_read Si7006_ADDR Si7006_MEAS_TEMP_MASTER_MODE
  log bytes_si7006_temp
  sleep (10)
  cTemp := (175.72 * (bytes_si7006_temp[0] * 256.0+ bytes_si7006_temp[1]) / 65536.0) - 46.85
  log "Temperature is $(%3.1f (cTemp) ) [C]"

  //Temperature in retard units
  fTemp := cTemp * 1.8 + 32
  log "Temperature is $(%3.1f (fTemp) ) [F]"
  relay.set 1