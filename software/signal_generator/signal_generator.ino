#include "signals.h"

#define X_PIN A0
#define Y_PIN A1
#define BUTTON_PIN 2

uint32_t t = 0;
uint8_t f = 0;

bool button_was_pressed = false;

bool button_toggled() {
  bool button_is_pressed = digitalRead(BUTTON_PIN);
  bool ret = !button_was_pressed && button_is_pressed;
  button_was_pressed = button_is_pressed;
  return ret;
}

void setup() {
  analogWriteResolution(12);
  pinMode(BUTTON_PIN, INPUT);
}

void loop() {
  t += 1;
  if (t >= NUM_TIMES) {
    t = 0;
  }

  if (button_toggled()) {
    f += 1;

    if (f >= NUM_FUNCS) {
      f = 0;
    }
  }

  uint32_t a = analogRead(A0) >> 4;

  uint32_t out = signals[f][a][t];
  analogWrite(DAC0, out);

  uint32_t delay = analogRead(A1) >> 4;
  delayMicroseconds(delay);
}
