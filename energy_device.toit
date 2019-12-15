// Copyright (C) 2019 Toitware ApS. All rights reserved.
import binary
import modules.i2c show *
import gpio
import metrics

class MCP39F521:
  device_ := null
  
  MCP39F521 .device_:
    
  // Read current stats
  register_read_stats -> Map:
    n_bytes_to_read := 32
    command_array := ByteArray 8

    command_array[0] = 0xA5             // Header byte
    command_array[1] = 0x08             // Number of bytes in frame
    command_array[2] = 0x41             // Set address pointer
    command_array[3] = 0x00             // Address high
    command_array[4] = 0x02             // Address low
    command_array[5] = 0x4E             // Register read, n bytes
    command_array[6] = 0x20             // Number of bytes to read (32)
    
    checksum := 0x00
    for i := 0; i < 7; i++:
      checksum += command_array[i]

    checksum = checksum % 256
    command_array[7] = checksum

    device_.write command_array         // Execute command

    sleep 20

    results := device_.read n_bytes_to_read + 3   // Return bytes
    
    voltage_rms := ((binary.LittleEndian results).uint16 6) / 10.0
    line_freq := ((binary.LittleEndian results).uint16 8) / 1000.0
    power_factor:= ((binary.LittleEndian results).int16 12) / 32768.0
    current_rms := ((binary.LittleEndian results).uint32 14) / 10000.0
    active_power := ((binary.LittleEndian results).uint32 18) / 100.0
    reactive_power := ((binary.LittleEndian results).uint32 22) / 100.0
    apparent_power := ((binary.LittleEndian results).uint32 26) / 100.0

    return {"voltage_rms": voltage_rms, 
            "line_freq": line_freq, 
            "power_factor": power_factor, 
            "current_rms": current_rms, 
            "active_power": active_power, 
            "reactive_power": reactive_power, 
            "apparent_power": apparent_power}

  // Read energy accumulation info
  register_read_accum -> Map:
    n_bytes_to_read := 32
    command_array := ByteArray 8

    command_array[0] = 0xA5                    // Header byte
    command_array[1] = 0x08                    // Number of bytes in frame
    command_array[2] = 0x41             // Set address pointer
    command_array[3] = 0x00             // Address high
    command_array[4] = 0x1E             // Address low
    command_array[5] = 0x4E             // Register read, n bytes
    command_array[6] = 0x20             // Number of bytes to read (32)
    checksum := 0x00
    for i := 0; i < 7; i++:
      checksum += command_array[i]
    
    checksum = checksum % 256
    command_array[7] = checksum         // Checksum

    device_.write command_array         // Execute command
    sleep 20

    results := device_.read n_bytes_to_read + 3  

    active_energy_accu := ((binary.LittleEndian results).uint32 2) / 1000000.0
    energy_cost := active_energy_accu * 1.4
    reactive_energy_accu := ((binary.LittleEndian results).uint32 18) / 1000000.0

    return {"active_energy_accumulation": active_energy_accu, 
            "energy_cost": energy_cost, 
            "reactive_energy_accumulation": reactive_energy_accu}

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
  
  // Reset energy accumulation
  reset_energy_accumulation -> none:
    this.set_energy_accumulation false
    sleep 50
    this.set_energy_accumulation true
    sleep 50
