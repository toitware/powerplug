// Copyright (C) 2019 Toitware ApS. All rights reserved.
import binary
import modules.i2c show *
import gpio

class MCP39F521:
  device_ := null

  MCP39F521 .device_:
  
  // Read 32 bytes from a given register and return a byte array
  register_read_stats -> ByteArray:
    n_bytes_to_read := 32
    command_array := ByteArray 8

    command_array[0] = 0xA5             // Header byte
    command_array[1] = 0x08             // Number of bytes in frame
    command_array[2] = 0x41             // Set address pointer
    command_array[3] = 0x00     // Address high
    command_array[4] = 0x02      // Address low
    command_array[5] = 0x4E             // Register read, n bytes
    command_array[6] = 0x20             // Number of bytes to read (32)
    checksum := 0x00
    for i := 0; i < 7; i++:
      checksum += command_array[i]
    
    checksum = checksum % 256
    command_array[7] = checksum         // Checksum

    device_.write command_array         // Execute command
    sleep 50
    return device_.read n_bytes_to_read + 3   // Return bytes

  register_read_accum -> ByteArray:
    n_bytes_to_read := 32
    command_array := ByteArray 8

    command_array[0] = 0xA5             // Header byte
    command_array[1] = 0x08             // Number of bytes in frame
    command_array[2] = 0x41             // Set address pointer
    command_array[3] = 0x00     // Address high
    command_array[4] = 0x1E      // Address low
    command_array[5] = 0x4E             // Register read, n bytes
    command_array[6] = 0x20             // Number of bytes to read (32)
    checksum := 0x00
    for i := 0; i < 7; i++:
      checksum += command_array[i]
    
    checksum = checksum % 256
    command_array[7] = checksum         // Checksum

    device_.write command_array         // Execute command
    sleep 50
    return device_.read n_bytes_to_read + 3   // Return bytes

  // Write to energy accumulation register
  set_energy_accumulation value/bool -> none:
    n_bytes_to_write := 2
    command_array := ByteArray 10

    command_array[0] = 0xA5             // Header byte
    command_array[1] = 0x0A             // Number of bytes in frame
    command_array[2] = 0x41             // Set address pointer
    command_array[3] = 0x00             // Address high
    command_array[4] = 0xDC             // Energy accumulation control register
    command_array[5] = 0x4D             // Register write, n bytes
    command_array[6] = 0x02             // Number of bytes to write (2)
    command_array[7] = 0x00             
      
    if value:                           // Reset or start energy accumulation
      command_array[8] = 0x01         
    else:                               // Stop energy accumulation  
      command_array[8] = 0x00

    checksum := 0x00
    for i := 0; i < 9; i++:
      checksum += command_array[i]

    checksum = checksum % 256
    command_array[9] = checksum

    device_.write command_array

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
  sleep 200
  
  // Connect device
  mcp_connection := i2c.connect 0x74
  sleep 50

  // 
  mcp := MCP39F521 mcp_connection
  sleep 50
  i := 0
  
  
  mcp.set_energy_accumulation false // Make sure there are no previous values in the registers
  sleep 500
  mcp.set_energy_accumulation true // Start accumulating
  while i < 16:
    mcp_stats := mcp.register_read_stats
    //log "status $((binary.LittleEndian mcp_stats).uint16 2)"
    //log "version $((binary.LittleEndian mcp_stats).uint16 4)"
    //$(%5.2f
    log "voltage rms $(%3.1f ((binary.LittleEndian mcp_stats).uint16 6) / 10.0) V"
    log "line freq $(%2.2f ((binary.LittleEndian mcp_stats).uint16 8) / 1000.0) Hz"
    //log "sar adc $(((binary.LittleEndian mcp_stats).uint16 10) / 1000.0)"
    log "power factor $(%1.2f ((binary.LittleEndian mcp_stats).int16 12) / 32768.0)"
    log "current rms $(%2.2f ((binary.LittleEndian mcp_stats).uint32 14) / 10000.0) Amp"
    log "active power  $(%5.2f ((binary.LittleEndian mcp_stats).uint32 18) / 100.0) Watt"
    log "reactive power  $(%5.2f ((binary.LittleEndian mcp_stats).uint32 22) / 100.0) Watt"
    log "apparent power $(%5.2f ((binary.LittleEndian mcp_stats).uint32 26) / 100.0) Watt"
    log "---"
    sleep 1000
    mcp_accumulation := mcp.register_read_accum
    log "Import active energy accumulation $(%5.6f ((binary.LittleEndian mcp_accumulation).uint32 2) / 1000000.0) kWh"
    log "The energy cost is $(%5.6f ((binary.LittleEndian mcp_accumulation).uint32 2) / 1000000.0*1.4) DKK"
    //log "Export Active Energy Counter $(((binary.LittleEndian mcp_accumulation).int64 10))"
    log "Import reactive energy accumulation $(%5.6f ((binary.LittleEndian mcp_accumulation).uint32 18) / 1000000.0) kWh"
    //log "Export Reactive Energy Counter $(((binary.LittleEndian mcp_accumulation).int64 26))"
    log "---"
    i += 1

  mcp.set_energy_accumulation false

  sleep 50
  relay.set 0
  sleep 100
  