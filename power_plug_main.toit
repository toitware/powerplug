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
    metrics.gauge "powerswitch_humidity" (humidity as Float)
    log "Humidity is $(%3.5f (humidity) ) [%]"
    sleep 100

    bytes_si7006_temp := si_device.read_temperature
    log bytes_si7006_temp

    cTemp := (175.72 * (bytes_si7006_temp[0] * 256.0 + bytes_si7006_temp[1]) / 65536.0) - 46.85
    log "Temperature is $(%3.2f (cTemp) ) [C]"
    metrics.gauge "powerswitch_temperature" (cTemp as Float)
    log "---"

    //electrical cirquit
    mcp_stats := mcp_device.register_read 0x00 0x02

    voltage_rms := (((binary.LittleEndian mcp_stats).uint16 6) / 10.0)
    log "voltage rms $(%3.1f voltage_rms) V"
    metrics.gauge "powerswitch_voltage_rms" (voltage_rms as Float)
    
    line_freq := ((binary.LittleEndian mcp_stats).uint16 8) / 1000.0
    log "line freq $(%2.2f line_freq) Hz"
    metrics.gauge "powerswitch_line_freq" (line_freq as Float)
    
    power_factor:= ((binary.LittleEndian mcp_stats).int16 12) / 32768.0
    log "power factor $(%1.2f power_factor)"
    metrics.gauge "powerswitch_power_factor" (power_factor as Float)

    current_rms := ((binary.LittleEndian mcp_stats).uint32 14) / 10000.0
    log "current rms $(%2.2f current_rms) Amp"
    metrics.gauge "powerswitch_current_rms" (current_rms as Float)

    active_power := ((binary.LittleEndian mcp_stats).uint32 18) / 100.0
    log "active power  $(%5.2f active_power) Watt"
    metrics.gauge "powerswitch_active_power" (active_power as Float)
    
    reactive_power := ((binary.LittleEndian mcp_stats).uint32 22) / 100.0
    log "reactive power  $(%5.2f reactive_power) Watt"
    metrics.gauge "powerswitch_reactive_power" (reactive_power as Float)
    
    apparent_power := ((binary.LittleEndian mcp_stats).uint32 26) / 100.0
    log "apparent power $(%5.2f apparent_power) Watt"
    metrics.gauge "powerswitch_apparent_power" (apparent_power as Float)
    
    log "---"
    sleep 1000
    mcp_accumulation := mcp_device.register_read 0x00 0x1E
    
    active_energy_accu := ((binary.LittleEndian mcp_accumulation).uint32 2) / 1000000.0
    log "Import active energy accumulation $(%5.6f active_energy_accu) kWh"
    metrics.gauge "powerswitch_active_energy_accu" (active_energy_accu as Float)
    
    
    energy_cost := ((binary.LittleEndian mcp_accumulation).uint32 2) / 1000000.0*1.4
    log "The energy cost is $(%5.6f energy_cost) DKK"
    metrics.gauge "powerswitch_energy_cost" (energy_cost as Float)
    
    
    reactive_energy_accu := ((binary.LittleEndian mcp_accumulation).uint32 18) / 1000000.0
    log "Import reactive energy accumulation $(%5.6f reactive_energy_accu) kWh"
    metrics.gauge "powerswitch_reactive_energy_accu" (reactive_energy_accu as Float)
    
    log "------------------"
     
    i += 1
  
  mcp_device.set_energy_accumulation false

  sleep 50
  relay.set 0
  sleep 100

