import .energy_device show *
import .th_device show *
import .led show *
import modules.i2c show *
import gpio
import metrics
import binary
import esp.esp32 show *

RELAY_PIN ::= 2
BLUE_PIN ::= 21
GREEN_PIN ::= 22
FREQUENCY ::= 400_000
SDA ::= 17
SCL ::= 16
ENERGY_DEVICE ::= 0x74
TH_DEVICE ::= 0x40

main:
  blue_led := Led (gpio.Pin BLUE_PIN)
  green_led := Led (gpio.Pin GREEN_PIN)
  blue_led.on

  i2c := I2C
    FREQUENCY
    gpio.Pin SDA
    gpio.Pin SCL

  button := Button 0

  relay := gpio.Pin RELAY_PIN
  relay.configure gpio.OUTPUT_CONF


  th_device := SI7006A20 (i2c.connect TH_DEVICE)           // Temperature and humidity
  energy_device := MCP39F521 (i2c.connect ENERGY_DEVICE)   // Electrical measurements

  
  /* measure_start := false
  measure := false
  while measure_start == false:
  if button.on_press 0:
    measure_start = true

  if measure_start:
    sleep 100
    blue_led.off
    sleep 1
    green_led.on
    sleep 1
    relay.set 1
    sleep 500
    measure = true
    energy_device.reset_energy_accumulation */

  i := 0
  while i < 10:
    // Humidity and temperature measurements 
    humidity := th_device.read_humidity
    metrics.gauge "powerswitch_humidity" humidity
    log "Humidity is $(%3.2f (humidity) ) %"

    temperature := th_device.read_humidity
    metrics.gauge "powerswitch_temperature" temperature
    log "Temperature is $(%3.2f (temperature) )˚C"

    log "---"
    
    sleep 20

    // Current electrial measurements
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


    // Accumulation measurements
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
    sleep 10
    /* if button.on 0 button.last_event:
      measure = false */
    i += 1

  sleep 1
  green_led.off
  blue_led.on
  sleep 100

  // Turning device off
  energy_device.set_energy_accumulation false
  sleep 50
  relay.set 0
  sleep 100
  blue_led.off
