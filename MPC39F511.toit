// Copyright (C) 2019 Toitware ApS. All rights reserved.
// TODO:
// put header byte, no of bytes in frame and checksum into block

class MPC39F511:
  // TODO: DETERMINE FIELDS

  // TODO: Implement, command id 0x4E
  registerReadNBytes:

  // TODO: Implement, command id 0x4D
  registerWriteNBytes:

  // More methods to come.

  static COMMAND_HEADER_BYTE            ::= 0xA5 
  static COMMAND_REGISTER_READ_N_BYTES  ::= 0x4E
  static COMMAND_REGISTER_WRITE_N_BYTES ::= 0x4D
  static COMMAND_SET_ADDRESS_POINTER    ::= 0x41