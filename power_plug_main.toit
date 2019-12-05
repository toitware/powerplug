import .MPC39F511 show *
import .temperature show *
import modules.i2c show *
import gpio

main:
  i2c := I2C
    400_000
    gpio.Pin 17
    gpio.Pin 16

  mcp_device := MCP39F521 (i2c.connect 0x74)
  
  si_device := SI7006A20 (i2c.connect 0x40)




