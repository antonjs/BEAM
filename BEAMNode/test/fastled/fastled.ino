/*
This is a basic example that will print out the header and the content of an ArtDmx packet.
This example uses the read() function and the different getter functions to read the data.
This example may be copied under the terms of the MIT license, see the LICENSE file for details
This works with ESP8266 and ESP32 based boards
*/

//#define FASTLED_INTERRUPT_RETRY_COUNT 0
#define FASTLED_ALLOW_INTERRUPTS 0

#include <FastLED.h>

#define FASTLED_ESP8266_D1_PIN_ORDER

#define DEVICE_NAME "beam01"
#define NUM_LEDS 100
#define FRONT_DATA_PIN 1
#define BACK_DATA_PIN 2
#define STATUS_DATA_PIN 3

CRGB front[NUM_LEDS];
CRGB back[NUM_LEDS];

void setup() {
  FastLED.addLeds<NEOPIXEL, FRONT_DATA_PIN>(front, NUM_LEDS);
  FastLED.addLeds<NEOPIXEL, BACK_DATA_PIN>(back, NUM_LEDS);
}

void loop() {
  for (int i = 0; i < NUM_LEDS; i++) {
    front[i] = CRGB::Red;
    delay(100);
    FastLED.show();
    
    front[i] = CRGB::Black;
    delay(100);
    FastLED.show();
  }
}
