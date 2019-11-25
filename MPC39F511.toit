// Copyright (C) 2019 Toitware ApS. All rights reserved.
import binary
import modules.i2c show *
import gpio

// TODO:
// put header byte, no of bytes in frame and checksum into block

class MPC39F511:
  // TODO: DETERMINE FIELDS
  i2c_ := null

  MPC39F511 .i2c_:
  
  // TODO: Implement, command id 0x4E
  registerReadNBytes address_high address_low:
    registers_ := i2c_.connect 0x74
    n_bytes := 32
    command_array := ByteArray 8
     
    command_array[0] = COMMAND_HEADER_BYTE
    command_array[1] = 0x08
    command_array[2] = COMMAND_SET_ADDRESS_POINTER
    command_array[3] = address_high
    command_array[4] = address_low
    command_array[5] = COMMAND_REGISTER_READ_N_BYTES
    command_array[6] = 0x20
    command_array[7] = 0x5E

    registers_.write command_array
    bytes := ByteArray n_bytes
    bytes = registers_.read n_bytes + 3 
    log "status $((binary.LittleEndian bytes).uint16 2)"
    log "version $((binary.LittleEndian bytes).uint16 4)"
    log "voltage rms $(((binary.LittleEndian bytes).uint16 6) / 10.0)"
    log "line freq $(((binary.LittleEndian bytes).uint16 8) / 1000.0)"
    //log "sar adc $(((binary.LittleEndian bytes).uint16 10) / 1000.0)"
    log "power factor $(((binary.LittleEndian bytes).int16 12) * 0.000030517578125)"
    log "current rms $(((binary.LittleEndian bytes).uint32 14) / 10000.0)"
    log "active power  $(((binary.LittleEndian bytes).uint32 18) / 100.0)"
    log "reactive power  $(((binary.LittleEndian bytes).uint32 22) / 100.0)"
    log "apparent power $(((binary.LittleEndian bytes).uint32 26) / 100.0)"

    log bytes

  static COMMAND_HEADER_BYTE            ::= 0xA5 
  static COMMAND_REGISTER_READ_N_BYTES  ::= 0x4E
  static COMMAND_REGISTER_WRITE_N_BYTES ::= 0x4D
  static COMMAND_SET_ADDRESS_POINTER    ::= 0x41


  // TODO: Implement, command id 0x4D
  //registerWriteNBytes:

  // More methods to come.

main:
  i2c := I2C
    400_000
    gpio.Pin 17
    gpio.Pin 16
  
  relay := gpio.Pin 2
  relay.configure gpio.OUTPUT_CONF
  
  relay.set 1
  sleep 500
  mpc := MPC39F511 i2c
  mpc.registerReadNBytes 0x00 0x02