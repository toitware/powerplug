import .MPC39F511 show *
import .temperature show *
import modules.i2c show *
import gpio
import metrics
import binary

RELAY_PIN ::= 2
FREQUENCY ::= 400_000
SDA ::= 17
SCL ::= 16
ENERGY_DEVICE ::= 0x74
TH_DEVICE ::= 0x40


main:
  relay := gpio.Pin RELAY_PIN
  relay.configure gpio.OUTPUT_CONF
  relay.set 1

  i2c := I2C
    FREQUENCY
    gpio.Pin SDA
    gpio.Pin SCL
  
  si_device := SI7006A20 (i2c.connect TH_DEVICE)      // Temperature and humidity
  mcp_device := MCP39F521 (i2c.connect ENERGY_DEVICE) // Electrical measurements
  

  i := 0
  while i < 60:
    
    /* Read and upload humidity*/
    si_device.read_humidity //sleep 20

    /*Read and upload temperature */
    si_device.read_temperature //sleep 20
    
    log "---"
    
    sleep 20

    /* Electrical circuit, read register and upload it to grafana*/
    mcp_device.upload_register_stats (mcp_device.register_read_stats) //sleep 20
    
    log "---"

    sleep 20
    /* Read accumulation register and push it to grafana */
    mcp_device.register_read_accum //sleep 20
    
    log "------"
    log ""

    sleep 59880
    i += 1
  
  /* Turning device off */
  mcp_device.set_energy_accumulation false // Turn off energy accumulation
  sleep 50
  relay.set 0                              // Turn off relay
  sleep 100
