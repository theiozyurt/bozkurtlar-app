#include <Arduino.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <esp_timer.h>
#include <esp_system.h>
#include "control_logic.h"

// Compatibility test: preserve the supplied original relay rule exactly.
// raw <= 700 -> LOW / "Musluk Acik"; raw > 700 -> HIGH / "Musluk Kapali".
// This is NOT a new assertion about sensor direction or physical pump state.
// Target: Deneyap Kart 1A (ESP32), Arduino IDE.
// Existing relay/driver required: NEVER connect a pump directly to D0.
constexpr int SENSOR_PIN = A0;
constexpr int RELAY_PIN = D0;
// Verify these three settings with your existing circuit before enabling a pump.
constexpr bool ENABLE_PUMP = true;
constexpr bool RELAY_ACTIVE_LOW = true;
constexpr bool LEVEL_INCREASES_WITH_WATER = false;
constexpr int THRESHOLD_ON = 700;
constexpr int THRESHOLD_OFF = 701;
static_assert(LEVEL_INCREASES_WITH_WATER ? THRESHOLD_OFF < THRESHOLD_ON : THRESHOLD_OFF > THRESHOLD_ON,
              "Threshold order does not match sensor direction");

constexpr char SERVICE_UUID[] = "6e400001-b5a3-f393-e0a9-e50e24dcca9e";
constexpr char TX_UUID[] = "6e400003-b5a3-f393-e0a9-e50e24dcca9e";
BLECharacteristic* tx = nullptr;
volatile bool deviceConnected = false;
volatile bool restartAdvertising = false;
bool pumpCommand = false;
bool critical = false;
uint32_t bootId = 0, sequence = 0, starts = 0;
uint64_t pumpOnMs = 0, criticalMs = 0, lastAccountMs = 0;
uint64_t lastSampleMs = 0, lastReportMs = 0;
int raw = 0;

class ServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer*) override { deviceConnected = true; }
  void onDisconnect(BLEServer*) override {
    deviceConnected = false;
    restartAdvertising = true;
  }
};

void setPump(bool on) {
  if (on && !pumpCommand) starts++;
  pumpCommand = on;
  digitalWrite(RELAY_PIN, RELAY_ACTIVE_LOW ? (on ? LOW : HIGH) : (on ? HIGH : LOW));
}

void setup() {
  Serial.begin(115200);
  pinMode(RELAY_PIN, OUTPUT);
  setPump(true); // Same LOW startup level as the supplied original code.
  analogReadResolution(12);
  raw = analogRead(SENSOR_PIN);
  setPump(raw <= THRESHOLD_ON);
  critical = raw <= THRESHOLD_ON;
  bootId = esp_random();
  BLEDevice::init("Bozkurtlar-1A");
  BLEServer* server = BLEDevice::createServer();
  server->setCallbacks(new ServerCallbacks());
  BLEService* service = server->createService(SERVICE_UUID);
  tx = service->createCharacteristic(TX_UUID, BLECharacteristic::PROPERTY_NOTIFY);
  tx->addDescriptor(new BLE2902());
  service->start();
  BLEAdvertising* advertising = BLEDevice::getAdvertising();
  advertising->addServiceUUID(SERVICE_UUID);
  advertising->setScanResponse(true);
  advertising->setMinPreferred(0x06);
  advertising->setMinPreferred(0x12);
  BLEDevice::startAdvertising();
  lastAccountMs = esp_timer_get_time() / 1000;
  Serial.println(ENABLE_PUMP ? "Pompa denetimi etkin." : "Pompa kilitli. Devre ayarlarini dogruladiktan sonra ENABLE_PUMP=true yapin.");
}

void loop() {
  // esp_timer avoids the 49-day millis() wraparound in cumulative counters.
  const uint64_t now = esp_timer_get_time() / 1000;
  const uint64_t dt = now - lastAccountMs;
  lastAccountMs = now;
  if (pumpCommand) pumpOnMs += dt;
  if (critical) criticalMs += dt;

  if (now - lastSampleMs >= 500) {
    lastSampleMs = now;
    raw = analogRead(SENSOR_PIN);
    critical = LEVEL_INCREASES_WITH_WATER ? raw >= THRESHOLD_ON : raw <= THRESHOLD_ON;
    const bool desired = ENABLE_PUMP && nextPumpState(pumpCommand, raw, LEVEL_INCREASES_WITH_WATER, THRESHOLD_ON, THRESHOLD_OFF);
    if (desired != pumpCommand) setPump(desired);
  }

  if (restartAdvertising) {
    restartAdvertising = false;
    BLEDevice::startAdvertising();
  }
  if (now - lastReportMs >= 1000) {
    lastReportMs = now;
    char frame[512];
    const int length = snprintf(frame, sizeof(frame),
      "{\"v\":1,\"boot\":%lu,\"seq\":%lu,\"raw\":%d,\"pump\":%s,\"critical\":%s,\"armed\":%s,\"rising\":%s,\"threshold_on\":%d,\"threshold_off\":%d,\"on_ms\":%llu,\"critical_ms\":%llu,\"starts\":%lu,\"uptime_ms\":%llu}\n",
      (unsigned long)bootId, (unsigned long)sequence++, raw,
      pumpCommand ? "true" : "false", critical ? "true" : "false", ENABLE_PUMP ? "true" : "false",
      LEVEL_INCREASES_WITH_WATER ? "true" : "false", THRESHOLD_ON, THRESHOLD_OFF,
      (unsigned long long)pumpOnMs, (unsigned long long)criticalMs, (unsigned long)starts, (unsigned long long)now);
    if (length > 0 && length < (int)sizeof(frame)) {
      Serial.print(frame);
      // 20 bytes fits default ATT MTU 23. Mobile reassembles until newline.
      if (deviceConnected) {
        for (int offset = 0; offset < length && deviceConnected; offset += 20) {
          const int count = min(20, length - offset);
          tx->setValue((uint8_t*)frame + offset, count);
          tx->notify();
          delay(5);
        }
      }
    }
  }
  delay(2);
}
