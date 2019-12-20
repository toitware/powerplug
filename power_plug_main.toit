import .energy_device show *
import .th_device show *
import modules.i2c show *
import gpio
import metrics
import binary
import esp.esp32 show *

RELAY_PIN     ::= 2
BLUE_PIN      ::= 21
GREEN_PIN     ::= 22
FREQUENCY     ::= 400_000
SDA           ::= 17
SCL           ::= 16
ENERGY_DEVICE ::= 0x74
TH_DEVICE     ::= 0x40

SAMPLING_TIME := 10000 //Measurement sampling time in ms

//Calibration of temperature unit
CALIBRATION_OFFSET := 6.8            //Steady offset representing difference between measured temp and real one when equilibrium is reached.
CALIBRATION_BASE := 0.6              //Base of exponential function approximating heat characteristics. Depends on how fast the device reaches steady state.
CALIBRATION_OFFSET_TRANSITIONAL := 3 //Offset that will exponentialy decrease in each iteration of measurement. Approximates the heating period of the device

main:

  i2c := I2C
    FREQUENCY
    gpio.Pin SDA
    gpio.Pin SCL

  blue := gpio.Pin 21
  blue.configure gpio.OUTPUT_CONF
  blue.set 0

  th_device := SI7006A20 (i2c.connect TH_DEVICE) SAMPLING_TIME CALIBRATION_OFFSET CALIBRATION_BASE CALIBRATION_OFFSET_TRANSITIONAL    // Temperature and humidity
  energy_device := MCP39F521 (i2c.connect ENERGY_DEVICE)   // Electrical measurements
  loop_iteration := 0
  

  while true:
    
    // Humidity and temperature measurements 
    humidity := th_device.read_humidity
    metrics.gauge "powerswitch_humidity" humidity
    log "Humidity is $(%3.2f (humidity) ) %"

    temperature_stats := th_device.read_temperature
    metrics.gauge "powerswitch_temperature_measured" (temperature_stats.get("temperature_measured"))
    log "Measured temperature is $(%3.2f (temperature_stats.get("temperature_measured")) )˚C"
    
    metrics.gauge "powerswitch_temperature_calibrated" (temperature_stats.get("temperature_calibrated"))
    log "Calibrated temperature is $(%3.2f (temperature_stats.get("temperature_calibrated")) )˚C"

    log "---"
    
    sleep 20

    // Print and gauge to grafana current electrial measurements
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


    // Print and gauge to grafana accumulation measurements
    accumulation := energy_device.register_read_accum
    log "Import active energy accumulation $(%5.6f accumulation.get("active_energy_accumulation")) kWh"
    metrics.gauge "powerswitch_active_energy_accu" (accumulation.get("active_energy_accumulation"))
    
    log "The energy cost is $(%5.6f accumulation.get("energy_cost")) DKK"
    metrics.gauge "powerswitch_energy_cost" (accumulation.get("energy_cost"))
    
    log "Import reactive energy accumulation $(%5.6f accumulation.get("reactive_energy_accumulation")) kWh"
    metrics.gauge "powerswitch_reactive_energy_accu" (accumulation.get("reactive_energy_accumulation"))
    log "------"
    log ""
    
    //If first gauge past we should set led to blue to indicate that device is uploading
    blue.set 1
    loop_iteration +=1

    sleep (SAMPLING_TIME - 120) //Wait until next minute

  sleep 100
  blue.set 0
  // Turning device off
  energy_device.set_energy_accumulation false
  sleep 50