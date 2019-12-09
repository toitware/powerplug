import .MPC39F511 show *
import .temperature show *
import modules.i2c show *
import gpio
import metrics
import binary

main:
  relay := gpio.Pin 2
  relay.configure gpio.OUTPUT_CONF
  relay.set 1
  
  
  i2c := I2C
    400_000
    gpio.Pin 17
    gpio.Pin 16
  
  mcp_device := MCP39F521 (i2c.connect 0x74) //electrical measurements
  
  si_device := SI7006A20 (i2c.connect 0x40) //temperature and humidity
  
  sleep 100
  mcp_device.set_energy_accumulation false // Make sure there are no previous values in the registers
  sleep 100
  mcp_device.set_energy_accumulation true // Start accumulating
  sleep 100

  i := 0
  while i < 2:
    
    //temperature and humidity
    
    bytes_si7006_hum := si_device.read_humidity
    log bytes_si7006_hum
    humidity := (125.0 * (bytes_si7006_hum[0] * 256.0 + bytes_si7006_hum[1]) / 65536.0) - 6.0	    
    log "Humidity is $(%3.5f (humidity) ) [%]"
    sleep 100

    bytes_si7006_temp := si_device.read_temperature
    log bytes_si7006_temp

    cTemp := (175.72 * (bytes_si7006_temp[0] * 256.0 + bytes_si7006_temp[1]) / 65536.0) - 46.85
    log "Temperature is $(%3.2f (cTemp) ) [C]"
    log "---"

    //electrical cirquit
    mcp_stats := mcp_device.register_read 0x00 0x02

    log "voltage rms $(%3.1f ((binary.LittleEndian mcp_stats).uint16 6) / 10.0) V"
    log "line freq $(%2.2f ((binary.LittleEndian mcp_stats).uint16 8) / 1000.0) Hz"
    log "power factor $(%1.2f ((binary.LittleEndian mcp_stats).int16 12) / 32768.0)"
    log "current rms $(%2.2f ((binary.LittleEndian mcp_stats).uint32 14) / 10000.0) Amp"
    log "active power  $(%5.2f ((binary.LittleEndian mcp_stats).uint32 18) / 100.0) Watt"
    log "reactive power  $(%5.2f ((binary.LittleEndian mcp_stats).uint32 22) / 100.0) Watt"
    log "apparent power $(%5.2f ((binary.LittleEndian mcp_stats).uint32 26) / 100.0) Watt"
    log "---"
    sleep 1000
    mcp_accumulation := mcp_device.register_read 0x00 0x1E
    log "Import active energy accumulation $(%5.6f ((binary.LittleEndian mcp_accumulation).uint32 2) / 1000000.0) kWh"
    log "The energy cost is $(%5.6f ((binary.LittleEndian mcp_accumulation).uint32 2) / 1000000.0*1.4) DKK"
    log "Import reactive energy accumulation $(%5.6f ((binary.LittleEndian mcp_accumulation).uint32 18) / 1000000.0) kWh"
    log "------------------"
     
    i += 1
  
  mcp_device.set_energy_accumulation false

  sleep 50
  relay.set 0
  sleep 100

