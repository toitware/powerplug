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

SAMPLING_TIME := 10000 //Measurement sampling time in ms. Don't go below 5000ms because the device might crash!
VERBOSITY := true

//Calibration of temperature unit
CALIBRATION_OFFSET := 8.6            //Steady offset representing difference between measured temp and real one when equilibrium is reached.
CALIBRATION_BASE := 0.6              //Base of exponential function approximating heat characteristics. Depends on how fast the device reaches steady state. It represents the fraction of transition value that will be reduced over a time of a minute
CALIBRATION_OFFSET_TRANSITIONAL := 1 //Offset that will exponentialy decrease in each iteration of measurement. Approximates the heating period of the device

main:

  i2c := I2C
    FREQUENCY
    gpio.Pin SDA
    gpio.Pin SCL

  blue := gpio.Pin 21
  blue.configure gpio.OUTPUT_CONF
  blue.set 0

  th_device := SI7006A20               // Temperature and humidity
    i2c.connect TH_DEVICE
    SAMPLING_TIME 
    CALIBRATION_OFFSET 
    CALIBRATION_BASE 
    CALIBRATION_OFFSET_TRANSITIONAL

  energy_device := MCP39F521           // Electrical measurements
    i2c.connect ENERGY_DEVICE 

  loop_iteration := 0
  while true:
    
    // Humidity and temperature measurements 
    humidity := th_device.read_humidity
    metrics.update_gauge "powerswitch_humidity" humidity
    
    temperature := th_device.read_temperature
    metrics.update_gauge "powerswitch_temperature_measured" (temperature.get("temperature_measured"))
    metrics.update_gauge "powerswitch_temperature_calibrated" (temperature.get("temperature_calibrated"))
    
    sleep --ms=20

    // Print and update_gauge to grafana current electrial measurements
    power_stats := energy_device.register_read_stats
    metrics.update_gauge "powerswitch_voltage_rms" (power_stats.get("voltage_rms"))
    metrics.update_gauge "powerswitch_line_freq" (power_stats.get("line_freq"))
    metrics.update_gauge "powerswitch_power_factor" (power_stats.get("power_factor"))
    metrics.update_gauge "powerswitch_current_rms" (power_stats.get("current_rms"))
    metrics.update_gauge "powerswitch_active_power" (power_stats.get("active_power"))
    metrics.update_gauge "powerswitch_reactive_power" (power_stats.get("reactive_power"))
    metrics.update_gauge "powerswitch_apparent_power" (power_stats.get("apparent_power"))
    
    sleep --ms=20

    // Print and update_gauge to grafana accumulation measurements
    accumulation := energy_device.register_read_accum
    metrics.update_gauge "powerswitch_active_energy_accu" (accumulation.get("active_energy_accumulation"))
    metrics.update_gauge "powerswitch_energy_cost" (accumulation.get("energy_cost"))
    metrics.update_gauge "powerswitch_reactive_energy_accu" (accumulation.get("reactive_energy_accumulation"))
    
    // If first update_gauge past we should set led to blue to indicate that device is uploading
    blue.set 1
    loop_iteration +=1
    
    if  VERBOSITY: 
      log "Humidity is $(%3.2f (humidity) ) %"
      log "Measured temperature is $(%3.2f (temperature.get("temperature_measured")) )˚C"
      log "Calibrated temperature is $(%3.2f (temperature.get("temperature_calibrated")) )˚C"
      log "---"
      log "voltage rms $(%3.1f power_stats.get("voltage_rms")) V"
      log "line freq $(%2.2f power_stats.get("line_freq")) Hz"
      log "power factor $(%1.2f power_stats.get("power_factor"))"
      log "current rms $(%2.2f power_stats.get("current_rms")) Amp"
      log "active power  $(%5.2f power_stats.get("active_power")) Watt"
      log "reactive power  $(%5.2f power_stats.get("reactive_power")) Watt"
      log "apparent power $(%5.2f power_stats.get("apparent_power")) Watt"
      log "---"
      log "Import active energy accumulation $(%5.6f accumulation.get("active_energy_accumulation")) kWh"
      log "The energy cost is $(%5.6f accumulation.get("energy_cost")) DKK"
      log "Import reactive energy accumulation $(%5.6f accumulation.get("reactive_energy_accumulation")) kWh"
      log "------"
      log ""


    sleep --ms=(SAMPLING_TIME - 120) // Wait until next minute

  sleep --ms=100
  blue.set 0
  // Turning device off
  energy_device.set_energy_accumulation false
  sleep --ms=50