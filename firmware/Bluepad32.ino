#include <Bluepad32.h>

Bluepad32::ControllerPad pad;

void setup() {
  Serial.begin(115200);
  Bluepad32.begin();
  pad.begin();
}

void loop() {
  Bluepad32.update();
  pad.update();
  if (pad.isConnected()) {
    // Handle button presses and analog inputs
  }
}
