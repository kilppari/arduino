// Simple Arduino control code for a sonar by using a servo + HC-SR04 ultrasonic sensor.
// Sensor angle and echo data is written to serial port
// Author: Pekka Makinen

#include <NewPing.h>
#include <Servo.h>

// Max echo distance in cm
// HC-SR04 specifies ranging distance of 2 - 400cm
#define MAX_ECHO_DIST 100

// Pin configuration
#define PIN_HC_SR04_TRIG 5
#define PIN_HC_SR04_ECHO 6
#define PIN_SERVO 10
#define PIN_ROTATION_TRIGGER 2

// Libraries for servo and sonar control
Servo servo;
NewPing sonar(PIN_HC_SR04_TRIG, PIN_HC_SR04_ECHO, MAX_ECHO_DIST); // Pin 5: Ouput trigger, Pin 6: Echo input

void setup()
{
  Serial.begin(9600);
  servo.attach(PIN_SERVO);
  servo.write(0);
  pinMode(PIN_ROTATION_TRIGGER, INPUT);
}

int i = 0;
int rotation_active = 0;
void loop()
{
  if(digitalRead(2) == HIGH) {
    rotation_active ^= 1;
    delay(500);
  }

  // While rotation is active:
  // Keep rotating servo between 10 and 110 degrees and at the same time ping HC-SR04 to get echo distance
  if(rotation_active) {
    int angle = (i>=100) ? (200 - i) : i;
    angle+=10; // Add some angle offset since the servo changes rotation more smoothly if we don't go to edge of rotation (0 degrees)
    servo.write(angle);
    delay(15);
    float echo_dist = (float)sonar.ping_cm() / MAX_ECHO_DIST; // Change distance to value between 0 - 1.
    // Write angle and echo distance to serial. Values separated by semicolumn.
    Serial.print(angle-10); // Remove offset so that receiving end doesn't have to care about it.
    Serial.print(";");
    Serial.println(echo_dist);
    delay(15);
    i++;
    if(i>=200) i=0;
  }
}
