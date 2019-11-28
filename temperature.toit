// Copyright (C) 2019 Toitware ApS. All rights reserved.
import binary
import modules.i2c show *
import gpio

//measure temperature, hold master mode , command code 0xE3
//read RH/T User Register 1 0xE7

Si7006_ADDR                             :=0x40 // default address
//Si7006 register addresses
Si7006_MEAS_REL_HUMIDITY_MASTER_MODE    :=0xE5
Si7006_MEAS_REL_HUMIDITY_NO_MASTER_MODE :=0xF5
Si7006_MEAS_TEMP_MASTER_MODE            :=0xE3
Si7006_MEAS_TEMP_NO_MASTER_MODE         :=0xF3
Si7006_READ_OLD_TEMP                    :=0xE0
Si7006_RESET 							:=0xFE
Si7006_WRITE_HUMIDITY_TEMP_CONTR		:=0xE6						
Si7006_READ_HUMIDITY_TEMP_CONTR 		:=0xE7
Si7006_WRITE_HEATER_CONTR				:=0x51
Si7006_READ_HEATER_CONTR				:=0x11
Si7006_READ_ID_LOW_0					:=0xFA
Si7006_READ_ID_LOW_1					:=0x0F
Si7006_READ_ID_HIGH_0					:=0xFC
Si7006_READ_ID_HIGH_1					:=0xC9
Si7006_FIRMWARE_0						:=0x84
Si7006_FIRMWARE_1						:=0xB8

modes := [Si7006_MEAS_REL_HUMIDITY_MASTER_MODE, Si7006_MEAS_REL_HUMIDITY_NO_MASTER_MODE, Si7006_MEAS_TEMP_MASTER_MODE, Si7006_MEAS_TEMP_NO_MASTER_MODE, Si7006_READ_OLD_TEMP, Si7006_RESET, Si7006_WRITE_HUMIDITY_TEMP_CONTR, Si7006_READ_HUMIDITY_TEMP_CONTR, Si7006_WRITE_HEATER_CONTR, Si7006_READ_HEATER_CONTR, Si7006_READ_ID_LOW_0, Si7006_READ_ID_LOW_1, Si7006_READ_ID_HIGH_0, Si7006_READ_ID_HIGH_1, Si7006_FIRMWARE_0, Si7006_FIRMWARE_1]

class SI7006A20:
  device_ := null

  SI7006A20 .device_:
  
  // Read 32 bytes from a given register and return a byte array
  register_read address mode-> ByteArray:
    n_bytes_to_read := 2
    command_array := ByteArray 2

    command_array[0] = address           // Header byte
    command_array[1] = mode //Si7006_MEAS_TEMP_NO_MASTER_MODE            // Number of bytes in frame
    /*command_array[2] = 0x00           // Set address pointer
    command_array[3] = 0x00        // Address
    command_array[4] = add           // Address low
    command_array[5] = 0x4E           // Register read, n bytes
    command_array[6] = 0x20           // Number of bytes to read (32)
    checksum := 0x00
    for i := 0; i < 7; i++:
      checksum += command_array[i]
    
    command_array[7] = checksum           // Checksum (92)
    log "checksum"
     */
    log command_array
    device_.write command_array       // Execute command
    ^device_.read_reg address n_bytes_to_read // Return bytes

  // Write n bytes to a given register

main:
  // Set pins for connection to device
  i2c := I2C
    400_000
    gpio.Pin 17
    gpio.Pin 16
  
  // Set relay for measuring
  relay := gpio.Pin 2
  relay.configure gpio.OUTPUT_CONF
  relay.set 1
  sleep 3000

  // Connect device
  device := i2c.connect Si7006_ADDR
  sleep(100)
  // Read output registers
  si7006a20 := SI7006A20 device
  for i:=0; i<16; i++:
    bytes_si7006 := si7006a20.register_read Si7006_ADDR modes[i]
    log bytes_si7006
    sleep (10)
  /*
  log "status $((binary.LittleEndian bytes_02_1A).uint16 2)"
  log "version $((binary.LittleEndian bytes_02_1A).uint16 4)"
  log "voltage rms $(((binary.LittleEndian bytes_02_1A).uint16 6) / 10.0)"
  log "line freq $(((binary.LittleEndian bytes_02_1A).uint16 8) / 1000.0)"
  //log "sar adc $(((binary.LittleEndian bytes_02_1A).uint16 10) / 1000.0)"
  log "power factor $(((binary.LittleEndian bytes_02_1A).int16 12) * 0.000030517578125)"
  log "current rms $(((binary.LittleEndian bytes_02_1A).uint32 14) / 10000.0)"
  log "active power  $(((binary.LittleEndian bytes_02_1A).uint32 18) / 100.0)"
  log "reactive power  $(((binary.LittleEndian bytes_02_1A).uint32 22) / 100.0)"
  log "apparent power $(((binary.LittleEndian bytes_02_1A).uint32 26) / 100.0)"
  */
  relay.set 0