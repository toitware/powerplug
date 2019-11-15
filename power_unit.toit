// Copyright (C) 2019 Toitware ApS. All rights reserved.

import serial
//import .bmx055
//Test
//Test

// Power_switch part of BMX055 (connected via spi).

class PowerSwitch extends Driver:

  PowerSwitch spi/serial.SpiRegisters:
    super spi

  on -> none:
    // Configure Power_switch
    spi_.write_u8 REG_BGW_SOFTRESET  0xB6 // reset Power_switch
    sleep 1000                              // Wait for all registers to reset
    validate_chip_id
    ABW_16Hz ::= 1
    ACCBW    ::= 0x08 | ABW_16Hz
    AFS_2G   ::= 0x03
    spi_.write_u8 REG_PMU_RANGE   AFS_2G  // Set Power_switch full range
    spi_.write_u8 REG_PMU_BW       ACCBW  // Set Power_switch bandwidth
    spi_.write_u8 REG_D_HBW          0x0  // Use filtered data
    spi_.write_u8 REG_INT_0        0x7F

    spi_.write_u8 REG_INT_MAP_0     0x00  // Controls which interrupt signals are mapped to the INT1 pin
    spi_.write_u8 REG_INT_EN_2     0x00  // Controls which interrupt signals are mapped to the INT1 pin

    spi_.write_u8 REG_INT_OUT_CTRL  0x00  // Set interrupts push-pull, active high for INT1 and INT2

    // spi_.write_u8 REG_INT_EN_0      0x03  // Enable ACC data ready interrupt
    spi_.write_u8 REG_INT_EN_1      0x12  // Enable ACC data ready interrupt
    spi_.write_u8 REG_INT_MAP_0     0x02  // Controls which interrupt signals are mapped to the INT1 pin = int1_high

    spi_.write_u8 REG_INT_EN_1 0x3 // Enable yx high-g interrupts
    spi_.write_u8 REG_INT_4 0xFF

    spi_.write_u8 REG_INT_RST_LATCH 0x7F

    // low-power mode 1
    spi_.write_u8 REG_PMU_LOW_POWER 0x00  // lowpower_mode set to ‘0’, sleeptimer_en = '0'
    spi_.write_u8 REG_PMU_LPW       0x5A  // lowpower_en = 1

    spi_.write_u8 REG_INT_3 0xFF
    // spi_.write_u8 REG_INT_6 0xFF // Contains the threshold definition for the any-motion interrupt.
    // spi_.write_u8 REG_INT_MAP_0    0x01  // Define INT1 (intACC1) as ACC data ready interrupt
    // spi_.write_u8 REG_BGW_SPI3_WDT 0x06  // Set watchdog timer for 50 ms

  get_d_value_ reg_lsb/int reg_msb/int -> int:
    lsb  ::= spi_.read_u8 reg_lsb
    msb ::= spi_.read_u8 reg_msb
    unless lsb & 0x1: ^null  // Bail out if there is no new data.
    value ::= ((msb << 8) | lsb) >> 4
    ^value <= 2047 ? value : value - 4096

  read -> Point:
    ^Point
      get_d_value_ REG_D_X_LSB REG_D_X_MSB
      get_d_value_ REG_D_Y_LSB REG_D_Y_MSB
      get_d_value_ REG_D_Z_LSB REG_D_Z_MSB

  validate_chip_id -> none:
    // Validate the chip ID
    id ::= spi_.read_u8 REG_CHIP_ID
    if id != CHIP_ID: throw "Unknown Power_switch chip id $id"

  // Registers for communicating with the Power_switch.

  //Steinunn part
  static REG_INSTR_POINTER ::= 0x00
  static REG_D_X_LSB       ::= 0x02
  static REG_D_X_MSB       ::= 0x03
  static REG_D_Y_LSB       ::= 0x04
  static REG_D_Y_MSB       ::= 0x05
  static REG_D_Z_LSB       ::= 0x06
  static REG_D_Z_MSB       ::= 0x07
  static REG_PMU_RANGE     ::= 0x0F
  static REG_PMU_BW        ::= 0x10
  static REG_D_HBW         ::= 0x13
  static REG_INT_EN_0      ::= 0x16
  static REG_INT_EN_1      ::= 0x17
  static REG_INT_EN_2      ::= 0x18
  static REG_INT_OUT_CTRL  ::= 0x20
  static REG_INT_MAP_0     ::= 0x19
  static REG_BGW_SPI3_WDT  ::= 0x34
  static REG_PMU_LPW       ::= 0x11
  static REG_PMU_LOW_POWER ::= 0x12
  static REG_INT_0         ::= 0x22

  //Chris
  static REG_INT_1         ::= 0x23
  static REG_INT_2         ::= 0x24
  static REG_INT_3         ::= 0x25
  static REG_INT_4         ::= 0x26
  static REG_INT_5         ::= 0x27
  static REG_INT_6         ::= 0x28
  static REG_INT_7         ::= 0x29
  static REG_INT_8         ::= 0x2A
  static REG_INT_9         ::= 0x2B
  static REG_INT_A         ::= 0x2C
  static REG_INT_B         ::= 0x2D
  static REG_INT_C         ::= 0x2E
  static REG_INT_D         ::= 0x2F
  static REG_BGW_SOFTRESET ::= 0x14
  static REG_INT_STATUS_0  ::= 0X09
  static REG_INT_STATUS_1  ::= 0X0A
  static REG_INT_STATUS_3  ::= 0x0C
  static REG_INT_RST_LATCH ::= 0x21

  // Expected result of reading REG_CHIP_ID.
  static CHIP_ID           ::= 0xFA

