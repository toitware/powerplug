// Copyright (C) 2019 Toitware ApS. All rights reserved.
import gpio
import serial

class PowerSwitch:

  // Register Map:
  // Output Registers:
  static REG_INSTR_POINTER      ::= 0x00 // u16 Address pointer for read or write commands
  static REG_SYS_STAT           ::= 0x02 // b16 System status register
  static REG_SYS_VERS           ::= 0x04 // u16 System Version, date code info
  static REG_VOLT_RMS           ::= 0x06 // u16 RMS Voltage output
  static REG_LINE_FREQ          ::= 0x08 // u16 Line Freq output
  static REG_A_INP_VOL          ::= 0x0A // u16 Output of the 10-bit SAR ADC 
  static REG_PWR_FACT           ::= 0x0C // s16 Power Factor output
  static REG_CURR_RMS           ::= 0x0E // u32 RMS Current output
  static REG_ACT_PWR            ::= 0x12 // u32 Active Power output
  static REG_REACT_PWR          ::= 0x16 // u32 Reactive Power output
  static REG_APP_PWR            ::= 0x1A // u32 Apparent Power output
  static REG_IMP_AEC            ::= 0x1E // u64 Accumulator for Active Energy, Import
  static REG_EXP_AEC            ::= 0x26 // u64 Accumulator for Active Energy, Export
  static REG_IMP_REC            ::= 0x2E // u64 Accumulator for Reactive Energy, Import
  static REG_EXP_REC            ::= 0x36 // u64 Accumulator for Reactive Energy, Export
  static REG_MIN_REC_1          ::= 0x3E // u32 Minimum Value of the Output Quantity Address in Min/Max Pointer 1 Register
  static REG_MIN_REC_2          ::= 0x42 // u32 Minimum Value of the Output Quantity Address in Min/Max Pointer 2 Register
  static REG_MAX_REC_1          ::= 0x4E // u32 Maximum Value of the Output Quantity Address in Min/Max Pointer 1 Register
  static REG_MAX_REC_2          ::= 0x52 // u32 Maximum Value of the Output Quantity Address in Min/Max Pointer 2 Register
  
  // Calibration Registers:
  static REG_CAL_DEL            ::= 0x5E // u16 May be used to initiate loading of the default calibration coefficients at start-up
  static REG_GN_CURR_RMS        ::= 0x60 // u16 Gain Calibration Factor for RMS Current
  static REG_GN_VOLT_RMS        ::= 0x62 // u16 Gain Calibration Factor for RMS Voltage
  static REG_GN_ACT_PWR         ::= 0x64 // u16 Gain Calibration Factor for Active Power
  static REG_GN_RACT_PWR        ::= 0x66 // u16 Gain Calibration Factor for Reactive Power
  static REG_OFF_CURR_RMS       ::= 0x68 // s32 Offset Calibration Factor for RMS Current
  static REG_OFF_ACT_PWR        ::= 0x6C // s32 Offset Calibration Factor for Active Power
  static REG_OFF_RACT_PWR       ::= 0x70 // s32 Offset Calibration Factor for Reactive Power
  static REG_DC_OFF_CURR        ::= 0x74 // s16 Offset Calibration Factor for DC Current
  static REG_PHASE_COMP         ::= 0x76 // s16 Phase Compensation 
  static REG_APP_PWR_DIV        ::= 0x78 // u16 Number of Digits for apparent power divisor to match IRMS and VRMS resolution 
  static REG_SYS_CONFIG         ::= 0x7A // b32 Control for device configuration, including ADC configuration
  
  // Design Configuration Registers:
  static REG_EVENT_CONFIG       ::= 0x7E // b16 Settings for the Event pin
  static REG_RANGE              ::= 0x82 // b32 Scaling factor for Outputs
  static REG_CAL_CURR           ::= 0x86 // u32 Target Current to be used during single-point calibration
  static REG_CAL_VOLT           ::= 0x8A // u16 Target Voltage to be used during single-point calibration
  static REG_CAL_PWR_ACT        ::= 0x8C // u32 Target Active Power to be used during single-point calibration
  static REG_CAL_PWR_RACT       ::= 0x90 // u32 Target Reactive Power to be used during single-point calibration
  static REG_LINE_FREQ_REF      ::= 0x94 // u16 Reference Value for the nominal line frequency
  static REG_ACC_INT_PARAM      ::= 0x9E // u16 N for 2N number of line cycles to be used during a single computation cycle
  static REG_VOLT_SAG_LIM       ::= 0xA0 // u16 RMS Voltage threshold at which an event flag is recorded
  static REG_VOLT_SURGE_LIM     ::= 0xA2 // u16 RMS Voltage threshold at which an event flag is recorded
  static REG_OVR_CURR_LIM       ::= 0xA4 // u32 RMS Current threshold at which an event flag is recorded
  static REG_OVR_PWR_LIM        ::= 0xA8 // u32 Active Power Limit at which an event flag is recorded
  
  // Temperature Compensation Registers:
  static REG_TEMP_COMP_FREQ     ::= 0xC6 // u16 Correction factor for compensating the line frequency indication over temperature
  static REG_TEMP_COMP_CURR     ::= 0xC8 // u16 Correction factor for compensating the Current RMS indication over temperature
  static REG_TEMP_COMP_PWR      ::= 0xCA // u16 Correction factor for compensating the active power indication over temperature
  static REG_AMB_TEMP_REF_VOLT  ::= 0xCC // u16 Register for storing the reference temperature during calibration
  
  // Control Registers for Peripherals
  static REG_MIN_MAX_POINTER_1  ::= 0xD4 // u16 Address Pointer for Min/Max 1 Outputs
  static REG_MIN_MAX_POINTER_2  ::= 0xD6 // u16 Address Pointer for Min/Max 2 Outputs
  static REG_ENERGY_CONTROL     ::= 0xDC // u16 Input register for reset/start of Energy Accumulation
  static REG_NO_LOAD_THRESH     ::= 0xE0 // u16 No-Load Threshold for Energy Counting
  