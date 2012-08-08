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
int http_trigger = 301;
//Making a var to keep a running count of the variable.  
int avlmem = 0;


///  FLOW METER STUFF HERE
volatile int state = LOW;
int interrupt_triggered = 0; // This is used for detemining if the interupt has happened
long timer;
int flow[] = {0, 0}; // This var is attached to the interupt and gets incremented on each flow count used for both kegs
///  END FLOW METER STUFF

void setup(void)
{
  pinMode(5, OUTPUT); // no fucking clue what I was doing here
  attachInterrupt(0, count_beer1, RISING); // setup the interrupt for keg1 digital pin 2
  attachInterrupt(1, count_beer2, RISING); // setup the interrupt for keg2 digital pin 3
  //  END FLOW METER STUFF  //
  // start serial port
  Serial.begin(9600);
  delay(1000);
  Serial.println();
  Serial.println("Applied Trust BevStats R2 'The Pi Edition'");

  // Start up the library
  sensors.begin();

  // locate devices on the bus
  Serial.print("Locating devices...");
  Serial.print("Found ");
  Serial.print(sensors.getDeviceCount(), DEC);
  Serial.println(" devices.");

  // report parasite power requirements
  Serial.print("Parasite power is: "); 
  if (sensors.isParasitePowerMode()) Serial.println("ON");
  else Serial.println("OFF");

  if (!sensors.getAddress(insideThermometer, 0)) Serial.println("Unable to find address for Device 0"); 
  if (!sensors.getAddress(outsideThermometer, 1)) Serial.println("Unable to find address for Device 1"); 

  // show the addresses we found on the bus
  Serial.print("Device 0 Address: ");
  printAddress(insideThermometer);
  Serial.println();

  Serial.print("Device 1 Address: ");
  printAddress(outsideThermometer);
  Serial.println();

  // set the resolution to 9 bit
  sensors.setResolution(insideThermometer, 9);
  sensors.setResolution(outsideThermometer, 9);

  Serial.print("Device 0 Resolution: ");
  Serial.print(sensors.getResolution(insideThermometer), DEC); 
  Serial.println();

  Serial.print("Device 1 Resolution: ");
  Serial.print(sensors.getResolution(outsideThermometer), DEC); 
  Serial.println();
}  

/////////////////////////////////////////////////////////////////////////
void loop(void)
{ 
  // call sensors.requestTemperatures() to issue a global temperature 
  // request to all devices on the bus
//  Serial.print("Requesting temperatures...");
  sensors.requestTemperatures();
//  Serial.println("DONE");
  if ((http_trigger > 300) || ((interrupt_triggered == 1 && (flow[0] >= 15 || flow[1] >= 15))))
  {
      sendData();
      interrupt_triggered = 0;
   if (http_trigger > 300){
      http_trigger = 0;
//      Serial.println("RESETTING HTTP_TRIGGER!");
   }     
  }
  delay(400);
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
    Serial.print(deviceAddress[i], HEX);
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
//  Serial.println("Getting Temps From within sendData");
  temp1 = DallasTemperature::toFahrenheit(printTemperature(insideThermometer));
  temp2 = DallasTemperature::toFahrenheit(printTemperature(outsideThermometer));
//  Serial.println("done getting temps in sendData");
//  Serial.print("avlmem ==");
//  Serial.println(avlmem);
  
  //Start building out get string
  char buffer[128];
  PString str(buffer, sizeof(buffer));
//  str = "GET /kegbot/check.php?temp1="; 
  str = "#,";
  str += temp1;
  str += ",";
  str += temp2;
  str += ",";
  str += flow[0];
  str += ",";
  str += flow[1];
  Serial.println(str);
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
//  timer = millis();
}

void count_beer2() {
  flow[1] += 1;
  interrupt_triggered = 1;
//  timer = millis();
}

