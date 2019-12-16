import gpio

main: 
 
  green := gpio.Pin 22
  green.configure gpio.OUTPUT_CONF

  red := gpio.Pin 23
  red.configure gpio.OUTPUT_CONF
 
  relay := gpio.Pin 2
  relay.configure gpio.OUTPUT_CONF

  button := gpio.Pin 0
  button.configure gpio.INPUT_CONF


  while true:
   green.set 0
   /*
   if blue == 0:
     red.set 1
   else:
     red.set 0
     */
   red.set 1
     
   relay.set 0
   
  //Wait for edge to turn it on
   button.wait_for 0
   sleep 100
   button.wait_for 1
  
  //Turn relay and green led on
   relay.set 1
   green.set 1
   red.set 0
   sleep 500

  //Wait for edge to turn it off
   button.wait_for 0
   sleep 100
   button.wait_for 1
   