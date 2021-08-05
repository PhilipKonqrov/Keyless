#include <SoftwareSerial.h>
SoftwareSerial BLE_Serial(0, 1); // RX - pin 0, TX - pin 1
String command = ""; // variable that contains text command sent from phone app.
uint8_t buff[50];
int i = 0;
char incoming = "";
// Define pins
#define ignition 2
#define starter 3
#define unlock 4
#define lock 5
#define headlights 6
void setup()
{
  Serial.begin(9600);
  BLE_Serial.begin(9600);//The default baudrate for the module is 9600
  BLE_Serial.println("READY");
  setupPins();
}

void setupPins() {
  pinMode(ignition, OUTPUT);
  pinMode(starter, OUTPUT);
  pinMode(unlock, OUTPUT);
  pinMode(lock, OUTPUT);
  pinMode(headlights, OUTPUT);
  
  digitalWrite(ignition, HIGH);
  digitalWrite(starter, HIGH);
  digitalWrite(unlock, HIGH);
  digitalWrite(lock, HIGH);
  digitalWrite(headlights, HIGH);
}

void loop() // run until the end of time
{
  if ( BLE_Serial.available() > 0 ) //Check to see if any data has streamed into the module
  {
    incoming = BLE_Serial.read();
    // 35 is number of # simbol. It's used for termination of the command
    if (incoming == 35) {
      command = (char*) buff;
//      Serial.println(command);
      i = 0;
      memset(buff, 0, sizeof(buff));
      execCommand();
    } else {
      buff[i] = incoming;
      i++;
    }
  }
}

void execCommand() {
  if (command == "ignOn") {
      digitalWrite(ignition, LOW);
      Serial.println("ignOn");
    } 
    else if (command == "ignOff") {
      digitalWrite(ignition, HIGH);
      Serial.println("ignOff");
    }
    else if (command == "startEngine") {
      digitalWrite(ignition, LOW);
      Serial.println("ignOn");
      delay(250);
      digitalWrite(starter, LOW);
      Serial.println("starterOn");
      delay(1000);
      digitalWrite(starter, HIGH);
      Serial.println("starterOff");
    }
    else if (command == "stopEngine") {
      digitalWrite(ignition, HIGH);
      Serial.println("ignOff");
    }
    else if (command == "unlock") {
      digitalWrite(unlock, LOW);
      Serial.println("unlockOn");
      delay(100);
      digitalWrite(unlock, HIGH);
      Serial.println("unlockOff");
    }
    else if (command == "lock") {
      digitalWrite(lock, LOW);
      Serial.println("lockOn");
      delay(100);
      digitalWrite(lock, HIGH);
      Serial.println("lockOff");
    }
    else if (command == "lightsOn") {
      digitalWrite(headlights, LOW);
      Serial.println("lightsOn");
    }
    else if (command == "lightsOff") {
      digitalWrite(headlights, HIGH);
      Serial.println("lightsOff");
    }
    else if (command == "sendParams") {
      if (digitalRead(ignition) == HIGH) {
        Serial.println("ignOff");
      } else {
        Serial.println("ignOn");
      }
      if (digitalRead(headlights) == HIGH) {
        Serial.println("lightsOff");
      } else {
        Serial.println("lightsOn");
      }
    }
}
