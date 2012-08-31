#include <SPI.h>
#include <PString.h>
#include <OneWire.h>
#include <DallasTemperature.h>
#include <avr/io.h>

// Data wire is plugged into port 2 (digital 8) on the Arduino
#define ONE_WIRE_BUS 8
#define TEMPERATURE_PRECISION 9

// Setup a oneWire instance to communicate with any OneWire devices (not just Maxim/Dallas temperature ICs)
OneWire oneWire(ONE_WIRE_BUS);

// Pass our oneWire reference to Dallas Temperature. 
DallasTemperature sensors(&oneWire);

// arrays to hold device addresses
DeviceAddress insideThermometer, outsideThermometer;
float temp1;
float temp2;
int http_trigger = 301; // this is still called http trigger because we used to use http, now we serial find and replace if you must

///  FLOW METER STUFF HERE
volatile int state = LOW;
int interrupt_triggered = 0; // This is used for detemining if the interupt has happened
int flow[] = {0, 0}; // This var is attached to the interupt and gets incremented on each flow count used for both kegs
///  END FLOW METER STUFF

void setup(void)
{
  attachInterrupt(0, count_beer1, RISING); // setup the interrupt for keg1 digital pin 2
  attachInterrupt(1, count_beer2, RISING); // setup the interrupt for keg2 digital pin 3
  //  END FLOW METER STUFF  //
  // start serial port
  Serial.begin(9600);
  delay(1000);

  // Start up the library
  sensors.begin();

  sensors.getAddress(insideThermometer, 0); 
  sensors.getAddress(outsideThermometer, 1);

  sensors.setResolution(insideThermometer, 9);
  sensors.setResolution(outsideThermometer, 9);
}  
/////////////////////////////////////////////////////////////////////////
void loop(void)
{ 
  // call sensors.requestTemperatures() to issue a global temperature 
  // request to all devices on the bus
  sensors.requestTemperatures();

  if ((http_trigger > 300) || ((interrupt_triggered == 1 && (flow[0] >= 15 || flow[1] >= 15))))
  {
      sendData();
      interrupt_triggered = 0;
   if (http_trigger > 300){
      http_trigger = 0;
   }     
  }
  // back to 400 for prod
  delay(40);
 http_trigger += 1;
}
/////////////////////////////////////////////////////////////////////////
// function to print a device address
void printAddress(DeviceAddress deviceAddress)
{
  for (uint8_t i = 0; i < 8; i++)
  {
    // zero pad the address if necessary
    if (deviceAddress[i] < 16) Serial.print("0");
    //Serial.print(deviceAddress[i], HEX);
  }
}
/////////////////////////////////////////////////////////////////////////
// main function to print information about a device
void printData(DeviceAddress deviceAddress)
{
  Serial.print("Device Address: ");
  printAddress(deviceAddress);
  Serial.print(" ");
  printTemperature(deviceAddress);
  Serial.println();
}
/////////////////////////////////////////////////////////////////////////
// function to print the temperature for a device
float printTemperature(DeviceAddress deviceAddress)
{
  float tempC = sensors.getTempC(deviceAddress);
  return tempC;
}
/////////////////////////////////////////////////////////////////////////
// function to send data to web server
void sendData()
{
  temp1 = DallasTemperature::toFahrenheit(printTemperature(insideThermometer));
  temp2 = DallasTemperature::toFahrenheit(printTemperature(outsideThermometer));

  //Start building out get string
  char buffer[32];
  PString str(buffer, sizeof(buffer));
  str = "";
  str += temp1;
  str += ",";
  str += temp2;
  str += ",";
  str += flow[0];
  str += ",";
  str += flow[1];
  Serial.println(str);
  // reset flow stats since we just submitted them to the Pi
  flow[0] = 0;
  flow[1] = 0;
}
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////
///  Flow Meter Intterrupt stuff  ///
////////////////////////////////////
void count_beer1() {
  flow[0] += 1;
  interrupt_triggered = 1;
}

void count_beer2() {
  flow[1] += 1;
  interrupt_triggered = 1;
}

