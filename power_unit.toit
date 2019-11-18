// Copyright (C) 2019 Toitware ApS. All rights reserved.
import gpio
import serial

class PowerSwitch:

  // Registers for communicating with the PowerSwitch.

  static REG_INSTR_POINTER      ::= 0x00 // Address pointer for read or write commands
  static REG_SYS_STAT           ::= 0x02 // 
  static REG_SYS_VERS           ::= 0x04 // 
  static REG_VOLT_RMS           ::= 0x06 // 
  static REG_LINE_FREQ          ::= 0x08 // 
  static REG_A_INP_VOL          ::= 0x0A // 
  static REG_PWR_FACT           ::= 0x0C // 
  static REG_CURR_RMS           ::= 0x0E // 
  static REG_ACT_PWR            ::= 0x12 // 
  static REG_REACT_PWR          ::= 0x16 // 
  static REG_APP_PWR            ::= 0x1A // 
  static REG_IMP_AEC            ::= 0x1E // 
  static REG_EXP_AEC            ::= 0x26 // 
  static REG_IMP_REC            ::= 0x2E // 
  static REG_EXP_REC            ::= 0x36 // 
  static REG_MIN_REC_1          ::= 0x3E // 
  static REG_MIN_REC_2          ::= 0x42 //
  static REG_MAX_REC_1          ::= 0x4E // 
  static REG_MAX_REC_2          ::= 0x52 // 
  static REG_CAL_DEL            ::= 0x5E // 
  static REG_GN_CURR_RMS        ::= 0x60 // 
  static REG_GN_VOLT_RMS        ::= 0x62 // 
  static REG_GN_ACT_PWR         ::= 0x64 // 
  static REG_GN_RACT_PWR        ::= 0x66 // 
  static REG_OFF_CURR_RMS       ::= 0x68 // 
  static REG_OFF_ACT_PWR        ::= 0x6C // 
  static REG_OFF_RACT_PWR       ::= 0x70 // 
  static REG_DC_OFF_CURR        ::= 0x74 // 
  static REG_PHASE_COMP         ::= 0x76 // 
  static REG_APP_PWR_DIV        ::= 0x78 //
  static REG_SYS_CONFIG         ::= 0x7A // 
  static REG_EVENT_CONFIG       ::= 0x7E //
  static REG_RANGE              ::= 0x82 // 
  static REG_CAL_CURR           ::= 0x86 // 
  static REG_CAL_VOLT           ::= 0x8A // 
  static REG_CAL_PWR_ACT        ::= 0x8C // 
  static REG_CAL_PWR_RACT       ::= 0x90 // 
  static REG_LINE_FREQ_REF      ::= 0x94 // 
  static REG_ACC_INT_PARAM      ::= 0x9E // 
  static REG_VOLT_SAG_LIM       ::= 0xA0 // 
  static REG_VOLT_SURGE_LIM     ::= 0xA2 // 
  static REG_OVR_CURR_LIM       ::= 0xA4 // 
  static REG_OVR_PWR_LIM        ::= 0xA8 // 
  static REG_TEMP_COMP_FREQ     ::= 0xC6 // 
  static REG_TEMP_COMP_CURR     ::= 0xC8 // 
  static REG_TEMP_COMP_PWR      ::= 0xCA // 
  static REG_AMB_TEMP_REF_VOLT  ::= 0xCC // 
  static REG_MIN_MAX_POINTER_1  ::= 0xD4 // 
  static REG_MIN_MAX_POINTER_2  ::= 0xD6 // 
  static REG_ENERGY_CONTROL     ::= 0xDC // 
  static REG_NO_LOAD_THRESH     ::= 0xE0 // 

