// Copyright (C) 2019 Toitware ApS. All rights reserved.
import serial show *
import modules.i2c show *
import gpio show *

// TODO:
// put header byte, no of bytes in frame and checksum into block

class MPC39F511:
  // TODO: DETERMINE FIELDS
  i2c_ := null

  // TODO: Implement, command id 0x4E
  registerReadNBytes address_high address_low n_bytes:
    byte_array_size := n_bytes + 3
    byte_array := ByteArray byte_array_size
    command_array := Array 8
     
    command_array[0] = COMMAND_HEADER_BYTE
    command_array[1] = 0x08
    command_array[2] = COMMAND_SET_ADDRESS_POINTER
    command_array[3] = address_high
    command_array[4] = address_low
    command_array[5] = COMMAND_REGISTER_READ_N_BYTES
    command_array[6] = n_bytes
    command_array[7] = 0

    checksumTotal := 0
    for i := 0; i < 7; i++:
      checksumTotal += command_array[i]

    command_array[7] = checksumTotal % 256

    registers := I2CRegisters i2c_


  static COMMAND_HEADER_BYTE            ::= 0xA5 
  static COMMAND_REGISTER_READ_N_BYTES  ::= 0x4E
  static COMMAND_REGISTER_WRITE_N_BYTES ::= 0x4D
  static COMMAND_SET_ADDRESS_POINTER    ::= 0x41


  // TODO: Implement, command id 0x4D
  registerWriteNBytes:

  // More methods to come.

main:
  i2c := I2C
    400_000
    Pin 17
    Pin 16

  mpc := MPC39F511
  mpc.i2c_ = i2c
  