/*  
 *  ------ [SX_05c] - TX LoRa to Meshlium-------- 
 *
 *  Explanation: This example shows how to configure the semtech 
 *  module in LoRa mode and then send packets to Meshlium.
 *  For this purpose, Waspmote Frames must be used.
 *
 *  Copyright (C) 2014 Libelium Comunicaciones Distribuidas S.L. 
 *  http://www.libelium.com 
 *  
 *  This program is free software: you can redistribute it and/or modify  
 *  it under the terms of the GNU General Public License as published by  
 *  the Free Software Foundation, either version 3 of the License, or  
 *  (at your option) any later version.  
 *   
 *  This program is distributed in the hope that it will be useful,  
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of  
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the  
 *  GNU General Public License for more details.  
 *   
 *  You should have received a copy of the GNU General Public License  
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.  
 *  
 *  Version:           0.1
 *  Design:            David Gascón 
 *  Implementation:    Covadonga Albiñana, Yuri Carmona
 */

// Include this library to transmit with sx1272
#include <WaspSX1272.h>
#include <WaspFrame.h>
//Tom
  #include <WaspOPC_N2.h>
  #include <WaspSensorGas_Pro.h>
  #include <WaspFrame.h>


  // Each object will be used by each gas sensor
  Gas CO(SOCKET_A);
  Gas O2(SOCKET_B);
  Gas CO2(SOCKET_C);
  Gas NO2(SOCKET_F);
//End

// define the Waspmote ID 
//////////////////////////////////////////
char nodeID[] = "Tom_monday_1";
//////////////////////////////////////////

  // Define the Meshlium address to send packets
  // The default Meshlium address is '1'
  uint8_t meshlium_address = 1;

 // status variable
//Tom
  float conc_CO;		// Stores the concentration level of CO in ppm
  float conc_O2;		// Stores the concentration level of O2 in ppm
  float conc_CO2;		// Stores the concentration level of CO2 in ppm
  float conc_NO2;		// Stores the concentration level of NO2 in ppm
  float temperature;	// Stores the temperature in ºC
  float humidity;		// Stores the realitve humidity in %RH
  float pressure;		// Stores the pressure in Pa
  int status;
  int measure;
//END
  int e;


  void setup()
 {
  // Init USB port
  USB.ON();
  USB.println(F("SE Pro Vitoria #1"));
  USB.println(F("Semtech SX1272 module. TX in LoRa to MESHLIUM"));

  // Switch ON RTC
  RTC.ON();

  // Switch ON ACC
  ACC.ON();

  // set the Waspmote ID
  frame.setID(nodeID);  

  USB.println(F("----------------------------------------"));
  USB.println(F("Setting configuration:")); 
  USB.println(F("----------------------------------------"));
  
  // Init sx1272 module
  sx1272.ON();

  // Select frequency channel
  e = sx1272.setChannel(CH_01_900);
  USB.print(F("Setting Channel CH_01_900.\t state ")); 
  USB.println(e);

  // Select implicit (off) or explicit (on) header mode
  e = sx1272.setHeaderON();
  USB.print(F("Setting Header ON.\t\t state "));  
  USB.println(e); 

  // Select mode (mode 1)
  e = sx1272.setMode(1);  
  USB.print(F("Setting Mode '1'.\t\t state "));
  USB.println(e);  

  // Select CRC on or off
  e = sx1272.setCRC_ON();
  USB.print(F("Setting CRC ON.\t\t\t state "));
  USB.println(e); 

  // Select output power (Max, High or Low)
  e = sx1272.setPower('H');
  USB.print(F("Setting Power to 'H'.\t\t state ")); 
  USB.println(e); 

  // Select the node address value: from 2 to 255
  e = sx1272.setNodeAddress(5);
  USB.print(F("Setting Node Address to '5'.\t state "));
  USB.println(e);
  USB.println();

  delay(1000);

}


void loop()
{
    USB.ON();
// Switch ON RTC
    RTC.ON();

  // Switch ON ACC
    ACC.ON();
  
    sx1272.ON();
  
  // get Time from RTC
  RTC.getTime();
  
//TOM
  
  ///////////////////////////////////////////
    // 1a. Turn on particle sensor
    ///////////////////////////////////////////  

    // Power on the OPC_N2 sensor. 
    // If the gases PRO board is off, turn it on automatically.
    status = OPC_N2.ON();
    if (status == 1)
    {
        USB.println(F("Particle sensor started"));

    }
    else
    {
        USB.println(F("Error starting the particle sensor"));
    }

    ///////////////////////////////////////////
    // 1b. Read the particle sensor
    ///////////////////////////////////////////  

    if (status == 1)
    {
        // Power the fan and the laser and perform a measure of 8 seconds
        measure = OPC_N2.getPM(8000);
        if (measure == 1)
        {
            USB.println(F("Measure performed"));
            USB.print(F("PM 1: "));
            USB.print(OPC_N2._PM1);
            USB.println(F(" ug/m3"));
            USB.print(F("PM 2.5: "));
            USB.print(OPC_N2._PM2_5);
            USB.println(F(" ug/m3"));
            USB.print(F("PM 10: "));
            USB.print(OPC_N2._PM10);
            USB.println(F(" ug/m3"));
        }
        else
        {
            USB.print(F("Error performing the measure. Error code:"));
            USB.println(measure, DEC);
        }
    }

    ///////////////////////////////////////////
    // 1c. Turn off the particle sensor
    /////////////////////////////////////////// 
    // Power off the OPC_N2 sensor. If there aren't other sensors powered, 
    // turn off the board automatically
    OPC_N2.OFF();

    delay(15000);

    USB.println(F("OPC_N2 off"));
    ///////////////////////////////////////////
    // 2a. Turn on gas sensors
    /////////////////////////////////////////// 

    // Power on the sensors. 
    // If the gases PRO board is off, turn it on automatically.
    CO.ON();
    O2.ON();
    CO2.ON();
    NO2.ON();

    // The sensor needs time to warm up and get a response from gas
    // To reduce the battery consumption, use deepSleep instead delay
    // After 2 minutes, Waspmote wakes up thanks to the RTC Alarm

    PWR.deepSleep("00:00:00:10", RTC_OFFSET, RTC_ALM1_MODE1, ALL_ON);


    ///////////////////////////////////////////
    // 2b. Read gas sensors
    ///////////////////////////////////////////  
    // Read the sensors and compensate with the temperature internally
    conc_CO = CO.getConc();
    conc_O2 = O2.getConc();
    conc_CO2 = CO2.getConc();
    conc_NO2 = NO2.getConc();

    // Read enviromental variables
    // In this case, CO objet has been used.
    // O2, CO2 or NO2 objects could be used with the same result
    temperature = CO.getTemp();
    humidity = CO.getHumidity();
    pressure = CO.getPressure();

    // And print the values via USB
    USB.println(F("***************************************"));
    USB.print(F("CO concentration: "));
    USB.print(conc_CO);
    USB.println(F(" ppm"));
    USB.print(F("O2 concentration: "));
    USB.print(conc_O2);
    USB.println(F(" ppm"));
    USB.print(F("CO2 concentration: "));
    USB.print(conc_CO2);
    USB.println(F(" ppm"));
    USB.print(F("NO2 concentration: "));
    USB.print(conc_NO2);
    USB.println(F(" ppm"));
    USB.print(F("Temperature: "));
    USB.print(temperature);
    USB.println(F(" Celsius degrees"));
    USB.print(F("RH: "));
    USB.print(humidity);
    USB.println(F(" %"));
    USB.print(F("Pressure: "));
    USB.print(pressure);
    USB.println(F(" Pa"));
//Tom
// Show the remaining battery level
  USB.print(F("Battery Level: "));
  USB.print(PWR.getBatteryLevel(),DEC);
  USB.print(F(" %"));
  
  // Show the battery Volts
  USB.print(F(" | Battery (Volts): "));
  USB.print(PWR.getBatteryVolts());
  USB.println(F(" V"));
//end

    ///////////////////////////////////////////
    // 2c. Turn off the gas sensors
    /////////////////////////////////////////// 

    // Power off the sensors sensor. If there aren't more gas sensors powered, 
    // turn off the board automatically
    CO.OFF();
    O2.OFF();
    CO2.OFF();
    NO2.OFF();
//END


  ///////////////////////////////////////////
  // 1. Create ASCII frame
  ///////////////////////////////////////////  

  USB.println(F("Create a new Frame:"));
  
//Tom
/////////////////////////////////////////////
  // 6. set frame size via parameter given by the user
  /////////////////////////////////////////////
  //frame.setFrameSize(256);

  USB.print(F("\nframe size given by the user (220):"));
  USB.println(frame.getFrameSize(),DEC);  
  delay(500);
//END

  // create new frame
  frame.createFrame(MAX_FRAME);  
  USB.println(frame.getFrameSize(),DEC);  
  // add frame fields
 // frame.addSensor(SENSOR_DATE, RTC.date, RTC.month, RTC.year);
//  frame.addSensor(SENSOR_TIME, RTC.hour, RTC.minute, RTC.second);
//  frame.addSensor(SENSOR_ACC, ACC.getX(), ACC.getY(), ACC.getZ());
//  frame.addSensor(SENSOR_BAT, PWR.getBatteryLevel()); 

     // Add CO concentration
    frame.addSensor(SENSOR_GP_CO, conc_CO);
    // Add O2 concentration
    frame.addSensor(SENSOR_GP_O2, conc_O2);
    // Add CO2 concentration
    frame.addSensor(SENSOR_GP_CO2, conc_CO2);
    // Add NO2 concentration
    frame.addSensor(SENSOR_GP_NO2, conc_NO2);
    // Add temperature
    frame.addSensor(SENSOR_GP_TC, temperature);
    // Add humidity
    frame.addSensor(SENSOR_GP_HUM, humidity);
    // Add pressure
    frame.addSensor(SENSOR_GP_PRES, pressure);	
    // Add PM 1
    frame.addSensor(SENSOR_OPC_PM1, OPC_N2._PM1); 
    // Add PM 2.5
    frame.addSensor(SENSOR_OPC_PM2_5, OPC_N2._PM2_5); 
    // Add PM 10
    frame.addSensor(SENSOR_OPC_PM10, OPC_N2._PM10); 
    // Add PM 10
    frame.addSensor(SENSOR_BAT, PWR.getBatteryLevel()); 


  // Prints frame
  frame.showFrame();


  ///////////////////////////////////////////
  // 2. Send packet
  ///////////////////////////////////////////  
  USB.println(F("----------------------------------------"));
  USB.println(F("Sending:")); 
  USB.println(F("----------------------------------------"));
  // Sending packet before ending a timeout
  e = sx1272.sendPacketTimeout( meshlium_address, frame.buffer, frame.length );
  
  // if ACK was received check signal strength
  if( e == 0 )
  {   
    USB.println(F("Packet sent OK"));     
  }
  else 
  {
    USB.println(F("Error sending the packet"));  
    USB.print(F("state: "));
    USB.println(e, DEC);
  } 

  USB.println();
  delay(2500);
  
      
//Tom
  // Go to deepsleep 
    // After 3 minutes, Waspmote wakes up thanks to the RTC Alarm
  // PWR.deepSleep("00:00:00:37", RTC_OFFSET, RTC_ALM1_MODE1, ALL_OFF);
 // PWR.deepSleep("00:00:00:37", RTC_OFFSET, RTC_ALM1_MODE2, ALL_OFF);
 // PWR.deepSleep("00:00:00:37",RTC_OFFSET,RTC_ALM1_MODE1,ALL_OFF);
//TOM

}


