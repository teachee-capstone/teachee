#include <EasyButton.h>

#include "signals.h"

#define X_PIN A0
#define Y_PIN A1
#define BUTTON_PIN A2

uint32_t t = 0;
uint8_t f = 0;

EasyButton button(BUTTON_PIN, true, true, false);

void handle_button() {
    f += 1;

    if (f >= NUM_FUNCS) {
      f = 0;
    }
}

void setup() {
  button.begin();
  button.onPressed(handle_button);

  analogWriteResolution(12);
}

void loop() {
  button.read();

  t += 1;
  if (t >= NUM_TIMES) {
    t = 0;
  }

  uint32_t a = analogRead(A0) >> 4;

  uint32_t out = signals[f][a][t];
  analogWrite(DAC0, out);

  uint32_t delay = analogRead(A1) >> 4;
  delayMicroseconds(delay);
}
