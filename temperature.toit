// Copyright (C) 2019 Toitware ApS. All rights reserved.
import binary
import modules.i2c show *
import gpio

class SI7006A20:
  device_ := null

  SI7006A20 .device_:
  
  // Read 32 bytes from a given register and return a byte array
  register_read address_high address_low -> ByteArray:
    n_bytes_to_read := 32
    command_array := ByteArray 8

    command_array[0] = 0xA5           // Header byte
    command_array[1] = 0x08           // Number of bytes in frame
    command_array[2] = 0x41           // Set address pointer
    command_array[3] = address_high   // Address high
    command_array[4] = address_low    // Address low
    command_array[5] = 0x4E           // Register read, n bytes
    command_array[6] = 0x20           // Number of bytes to read (32)
    checksum := 0x00
    for i := 0; i < 7; i++:
      checksum += command_array[i]
    
    command_array[7] = checksum           // Checksum (92)

    device_.write command_array       // Execute command
    ^device_.read n_bytes_to_read + 3 // Return bytes

  // Write n bytes to a given register

main:
  // Set pins for connection to device
  i2c := I2C
    400_000
    gpio.Pin 17
    gpio.Pin 16
  
  // Connect device
  device := i2c.connect 0x40

  // Read output registers
  si7006a20 := SI7006A20 device
  bytes_02_1A := si7006a20.register_read 0x00 0x02

  log bytes_02_1A
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