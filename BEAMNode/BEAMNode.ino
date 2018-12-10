/*
This is a basic example that will print out the header and the content of an ArtDmx packet.
This example uses the read() function and the different getter functions to read the data.
This example may be copied under the terms of the MIT license, see the LICENSE file for details
This works with ESP8266 and ESP32 based boards
*/

#include <ESP8266WiFi.h>        // Include the Wi-Fi library
#include <ESP8266WiFiMulti.h>   // Include the Wi-Fi-Multi library
#include <ESP8266mDNS.h>        // Include the mDNS library

#include "Artnet.h"

//#define FASTLED_ALLOW_INTERRUPTS 0
#define FASTLED_INTERRUPT_RETRY_COUNT 0
#define FASTLED_ESP8266_D1_PIN_ORDER

#include <FastLED.h>

#define DEVICE_NAME "beam01"
#define BEAM_WIFI_SSID "BEAM"
#define BEAM_WIFI_PASSWORD "thereisnospoon"

#define NUM_LEDS 100
#define FRONT_DATA_PIN 1
#define BACK_DATA_PIN 2
#define STATUS_DATA_PIN 3

ESP8266WiFiMulti wifiMulti;

const char* ssid     = "Aperture Science";
const char* password = "stillalive";

Artnet artnet;

CRGB front[NUM_LEDS];
CRGB back[NUM_LEDS];

void setup()
{
//  wifiMulti.addAP("DeMaTeriaLX", "lightyourdome");
//  wifiMulti.addAP("Aperture Science", "stillalive");
//  wifiMulti.addAP("The Dish", "coronetpeak");
  wifiMulti.addAP(BEAM_WIFI_SSID, BEAM_WIFI_PASSWORD);
  
  WiFi.setSleepMode(WIFI_NONE_SLEEP);

  int count = 0;
  while (wifiMulti.run() != WL_CONNECTED) {
    delay(250);
    count++;

    if (count > 40) {
      WiFi.softAP(BEAM_WIFI_SSID, BEAM_WIFI_PASSWORD); 
      break;
    }
  }

  MDNS.begin(DEVICE_NAME);

  FastLED.addLeds<NEOPIXEL, FRONT_DATA_PIN>(front, NUM_LEDS);
  FastLED.addLeds<NEOPIXEL, BACK_DATA_PIN>(back, NUM_LEDS);

  for (int i = 0; i < 10; i++) {
    front[0] = CRGB::Red;
    delay(100);
    FastLED.show();
    
    front[0] = CRGB::Black;
    delay(100);
    FastLED.show();
  }

  artnet.setArtDmxCallback(dmxFrame);
  artnet.begin();
}

void dmxFrame(uint16_t universe, uint16_t length, uint8_t sequence, uint8_t* data, IPAddress remoteIP) {
//  for (int i = 0; i < length; i += 3) {
//    leds[i].red = data[i]
//    leds[i].green = data[i+1]
//    leds[i].blue = data[i+2]  
//  }

  if (length > 3 * NUM_LEDS) return;
  
  switch (universe) {
    case 0:
      memcpy8(&front, data, length);
      break;
    case 4:
      memcpy8(&back, data, length);
      break;
  }

  FastLED.show();
}

void loop()
{
  if (artnet.read() == ART_DMX) {
  }
}
