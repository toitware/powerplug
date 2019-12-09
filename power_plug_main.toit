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
  
  sleep 100
  mcp_device.set_energy_accumulation false            // Make sure there are no previous values in the registers
  sleep 100
  mcp_device.set_energy_accumulation true             // Start accumulating
  sleep 50

  i := 0
  while i < 2:
    
    /* Temperature and humidity */
    humidity := si_device.read_humidity
    metrics.gauge "powerswitch_humidity" humidity
    log "Humidity is $(%3.5f (humidity) ) [%]"

    sleep 10

    temperature := si_device.read_temperature
    log "Temperature is $(%3.2f (temperature) ) [C]"
    metrics.gauge "powerswitch_temperature" temperature
    log "---"

    /* Electrical circuit */
    mcp_stats := mcp_device.register_read_stats

    voltage_rms := (((binary.LittleEndian mcp_stats).uint16 6) / 10.0)
    log "voltage rms $(%3.1f voltage_rms) V"
    metrics.gauge "powerswitch_voltage_rms" voltage_rms
    
    line_freq := ((binary.LittleEndian mcp_stats).uint16 8) / 1000.0
    log "line freq $(%2.2f line_freq) Hz"
    metrics.gauge "powerswitch_line_freq" line_freq
    
    power_factor:= ((binary.LittleEndian mcp_stats).int16 12) / 32768.0
    log "power factor $(%1.2f power_factor)"
    metrics.gauge "powerswitch_power_factor" power_factor

    current_rms := ((binary.LittleEndian mcp_stats).uint32 14) / 10000.0
    log "current rms $(%2.2f current_rms) Amp"
    metrics.gauge "powerswitch_current_rms" current_rms

    active_power := ((binary.LittleEndian mcp_stats).uint32 18) / 100.0
    log "active power  $(%5.2f active_power) Watt"
    metrics.gauge "powerswitch_active_power" active_power
    
    reactive_power := ((binary.LittleEndian mcp_stats).uint32 22) / 100.0
    log "reactive power  $(%5.2f reactive_power) Watt"
    metrics.gauge "powerswitch_reactive_power" reactive_power
    
    apparent_power := ((binary.LittleEndian mcp_stats).uint32 26) / 100.0
    log "apparent power $(%5.2f apparent_power) Watt"
    metrics.gauge "powerswitch_apparent_power" apparent_power
    
    log "---"
    sleep 1000
    mcp_accumulation := mcp_device.register_read_accum
    
    active_energy_accu := ((binary.LittleEndian mcp_accumulation).uint32 2) / 1000000.0
    log "Import active energy accumulation $(%5.6f active_energy_accu) kWh"
    metrics.gauge "powerswitch_active_energy_accu" active_energy_accu
    
    energy_cost := ((binary.LittleEndian mcp_accumulation).uint32 2) / 1000000.0*1.4
    log "The energy cost is $(%5.6f energy_cost) DKK"
    metrics.gauge "powerswitch_energy_cost" energy_cost
    
    reactive_energy_accu := ((binary.LittleEndian mcp_accumulation).uint32 18) / 1000000.0
    log "Import reactive energy accumulation $(%5.6f reactive_energy_accu) kWh"
    metrics.gauge "powerswitch_reactive_energy_accu" reactive_energy_accu
    
    log "------------------"
     
    i += 1
  
  mcp_device.set_energy_accumulation false // Turn off energy accumulation

  sleep 50
  relay.set 0                              // Turn off relay
  sleep 100
