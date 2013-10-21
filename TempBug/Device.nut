// pin 9 is the middle of the voltage divider formed by the NTC - read the analog voltage to determine temperature
hardware.pin9.configure(ANALOG_IN);

// all calculations are done in Kelvin

const b_therm = 3988;
const t0_therm = 298.15;

local calcBatt = [10, 20];

function getTemp() {
  ///
  // benchmarking: see how long thermistor is "on"
  local ton = hardware.micros();
  // turn on the thermistor network
  hardware.pin8.write(0);

  // gather several ADC readings and average them (just takes out some noise)
  local val = 0;
  for (local i = 0; i < 10; i++) {
      imp.sleep(0.01);
      val += hardware.pin9.read();
  }
  // turn the thermistor network back off
  hardware.pin8.write(1);
  local toff = hardware.micros();
  server.log(format("Thermistor Network on for %d us", (toff-ton)));
  
  val = val/10;


server.log("b_therm "+ b_therm);
server.log("t0_therm "+ t0_therm);
  // scale the ADC reading to a voltage by dividing by the full-scale value and multiplying by the supply voltage
  local v_therm = calcBatt[0] * val / 65535.0;
  server.log("v_therm "+ v_therm);
  // calculate the resistance of the thermistor at the current temperature
  local r_therm = 10000.0 / ( calcBatt[0] / v_therm ) - 1;
  server.log("r_therm "+ r_therm);
  local ln_therm = math.log(10000.0 / r_therm);
  server.log("ln_therm "+ ln_therm);
  
  local t_therm = (t0_therm * b_therm) / (b_therm - (t0_therm * ln_therm)) - 273.15;
  server.log("t_therm "+ t_therm);
  ///
  
  // convert to fahrenheit for the less-scientific among us
  local f = (t_therm) * (9.0 / 5.0) + 32.0;
  // format into a string for the string output port
  local f_str = format("%.01f",f)
  server.log("Current temp is "+f_str+" F");
  
  agent.send("temp", f);
  //agent.send("Batt", imp.Batt());
  agent.send("Batt", calcBatt[0]);
  
  imp.onidle(function() { server.sleepfor(900); });   // 15 minutes
  
}

function readBatt() {

  // to read the battery voltage reliably, we take 10 readings and average them
  local v_high  = 0;
  for(local i = 0; i < 10; i++){
    imp.sleep(0.01);
    
    local voltage = hardware.voltage();
    local reading = hardware.pin9.read();
    v_high += (reading/65536.0)*voltage;
  
  }
  v_high = v_high / 10.0;
  
  // update the current battery voltage with a nicely-formatted string of the most recently-calculated value
  local batt_str = format("%.02f",v_high)
  
  // a bit off reading a 9V batt: http://devwiki.electricimp.com/doku.php?id=electricimpapi:hardware:voltage
  server.log("Battery Voltage is "+batt_str+" V");
  
 calcBatt[0] = v_high;

}

imp.configure("TempBug1", [], []);
//server.log(format("Batt %ddBm",imp.Batt()));

readBatt()
getTemp()
