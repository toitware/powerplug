import gpio

class Led:
  pin_ := null

  Led .pin_:
    pin_.configure gpio.OUTPUT_CONF
    this.off

  on:
    pin_.set 1
    sleep 10

  off:
    pin_.set 0
    sleep 10
