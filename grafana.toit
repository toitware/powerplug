import metrics
main: 
  metrics.gauge "foo" 17.0 //--tags={"abcd":"efgh"} 