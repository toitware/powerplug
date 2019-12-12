import .energy_device show *
import .th_device show *
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
  
  i2c := I2C
    FREQUENCY
    gpio.Pin SDA
    gpio.Pin SCL
  
  th_device := SI7006A20 (i2c.connect TH_DEVICE)      // Temperature and humidity
  energy_device := MCP39F521 (i2c.connect ENERGY_DEVICE) // Electrical measurements

  relay.set 1
  sleep 1000

  i := 0
  while i < 15:
    
    /* Read and upload humidity*/
    humidity := th_device.read_humidity
    metrics.gauge "powerswitch_humidity" humidity
    log "Humidity is $(%3.2f (humidity) ) %"

    /* Read and upload temperature */
    temperature := th_device.read_humidity
    metrics.gauge "powerswitch_temperature" temperature
    log "Temperature is $(%3.2f (temperature) )˚C"

    log "---"
    
    sleep 20

    /* Electrical circuit, read register and upload it to grafana*/
    power_stats := energy_device.register_read_stats
    log "voltage rms $(%3.1f power_stats.get("voltage_rms")) V"
    metrics.gauge "powerswitch_voltage_rms" (power_stats.get("voltage_rms"))

    log "line freq $(%2.2f power_stats.get("line_freq")) Hz"
    metrics.gauge "powerswitch_line_freq" (power_stats.get("line_freq"))
    
    log "power factor $(%1.2f power_stats.get("power_factor"))"
    metrics.gauge "powerswitch_power_factor" (power_stats.get("power_factor"))

    log "current rms $(%2.2f power_stats.get("current_rms")) Amp"
    metrics.gauge "powerswitch_current_rms" (power_stats.get("current_rms"))

    log "active power  $(%5.2f power_stats.get("active_power")) Watt"
    metrics.gauge "powerswitch_active_power" (power_stats.get("active_power"))
    
    log "reactive power  $(%5.2f power_stats.get("reactive_power")) Watt"
    metrics.gauge "powerswitch_reactive_power" (power_stats.get("reactive_power"))
    
    log "apparent power $(%5.2f power_stats.get("apparent_power")) Watt"
    metrics.gauge "powerswitch_apparent_power" (power_stats.get("apparent_power"))
    log "---"

    sleep 20

    /* Read accumulation register and push it to grafana */
    accumulation := energy_device.register_read_accum
    log "Import active energy accumulation $(%5.6f accumulation.get("active_energy_accumulation")) kWh"
    metrics.gauge "powerswitch_active_energy_accu" (accumulation.get("active_energy_accumulation"))
    
    log "The energy cost is $(%5.6f accumulation.get("energy_cost")) DKK"
    metrics.gauge "powerswitch_energy_cost" (accumulation.get("energy_cost"))
    
    log "Import reactive energy accumulation $(%5.6f accumulation.get("reactive_energy_accumulation")) kWh"
    metrics.gauge "powerswitch_reactive_energy_accu" (accumulation.get("reactive_energy_accumulation"))
    log "------"
    log ""

    //sleep 59880
    i += 1
  
  /* Turning device off */
  energy_device.set_energy_accumulation false
  sleep 50
  relay.set 0
  sleep 100
