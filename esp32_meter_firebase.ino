#include <WiFi.h>
#include <HTTPClient.h>
#include <ModbusMaster.h>

// --- Pin Definitions ---
#define MAX485_DE_RE   25
#define MODBUS_RX_PIN  26
#define MODBUS_TX_PIN  27

// --- Meter Configuration ---
#define METER_BAUD     9600
#define METER_SLAVE_ID 1

// --- Wi-Fi Credentials ---
const char* WIFI_SSID = "Shivam1234";
const char* WIFI_PASS = "Shivam@112";

// --- Shivam Cloud API (issued once, when you pair this meter in the app) ---
const char* API_URL     = "https://REGION-YOUR-PROJECT.cloudfunctions.net/ingest"; // fill in after deploy
const char* DEVICE_ID   = "SHV-ESP-0142";       // from the app's pairing screen
const char* DEVICE_APIKEY = "paste-the-api-key-shown-once-at-pairing";

const unsigned long UPLOAD_INTERVAL_MS = 16000;
unsigned long lastUpload = 0;

ModbusMaster node;
WiFiClient client;

void preTransmission()  { digitalWrite(MAX485_DE_RE, HIGH); }
void postTransmission() { digitalWrite(MAX485_DE_RE, LOW);  }

float readModbusFloat(uint16_t reg) {
  uint16_t protocolAddress = reg - 40001;

  uint8_t result = node.readHoldingRegisters(protocolAddress, 2);
  if (result != node.ku8MBSuccess) {
    result = node.readInputRegisters(protocolAddress, 2);
  }

  if (result == node.ku8MBSuccess) {
    // NOTE: if readings look nonsensical, swap the word order below —
    // meters vary on whether the high or low word comes first.
    uint32_t temp = ((uint32_t)node.getResponseBuffer(1) << 16) | node.getResponseBuffer(0);
    float value;
    memcpy(&value, &temp, sizeof(float));
    return value;
  }
  return -1.0;
}

void ensureWifi() {
  if (WiFi.status() == WL_CONNECTED) return;
  Serial.print("Reconnecting Wi-Fi");
  WiFi.begin(WIFI_SSID, WIFI_PASS);
  unsigned long start = millis();
  while (WiFi.status() != WL_CONNECTED && millis() - start < 15000) {
    delay(500);
    Serial.print(".");
  }
  Serial.println(WiFi.status() == WL_CONNECTED ? "\nReconnected." : "\nStill offline.");
}

void setup() {
  Serial.begin(115200);
  pinMode(MAX485_DE_RE, OUTPUT);
  digitalWrite(MAX485_DE_RE, LOW);

  Serial2.begin(METER_BAUD, SERIAL_8E1, MODBUS_RX_PIN, MODBUS_TX_PIN);
  node.begin(METER_SLAVE_ID, Serial2);
  node.preTransmission(preTransmission);
  node.postTransmission(postTransmission);

  WiFi.begin(WIFI_SSID, WIFI_PASS);
  Serial.print("Connecting to Wi-Fi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nWi-Fi Connected!");
}

void loop() {
  ensureWifi();

  float vll_avg = readModbusFloat(40133); delay(30);
  float vll_ry  = readModbusFloat(40127); delay(30);
  float vll_yb  = readModbusFloat(40129); delay(30);
  float vll_br  = readModbusFloat(40131); delay(30);

  float cur_avg = readModbusFloat(40149); delay(30);
  float cur_r   = readModbusFloat(40143); delay(30);
  float cur_y   = readModbusFloat(40145); delay(30);
  float cur_b   = readModbusFloat(40147);

  bool allValid = (vll_avg >= 0 && vll_ry >= 0 && vll_yb >= 0 && vll_br >= 0 &&
                    cur_avg >= 0 && cur_r   >= 0 && cur_y  >= 0 && cur_b   >= 0);

  if (allValid) {
    Serial.printf("VLL [Avg:%.1f | RY:%.1f | YB:%.1f | BR:%.1f] | CUR [Avg:%.2f | R:%.2f | Y:%.2f | B:%.2f]\n",
                  vll_avg, vll_ry, vll_yb, vll_br, cur_avg, cur_r, cur_y, cur_b);
  } else {
    Serial.println("Modbus Read Failed on one or more phase registers.");
  }

  if (millis() - lastUpload > UPLOAD_INTERVAL_MS) {
    if (allValid && WiFi.status() == WL_CONNECTED) {
      lastUpload = millis();

      HTTPClient http;
      http.begin(client, API_URL);
      http.addHeader("Content-Type", "application/json");

      String payload = String("{") +
        "\"deviceId\":\"" + DEVICE_ID + "\"," +
        "\"apiKey\":\"" + DEVICE_APIKEY + "\"," +
        "\"vll_avg\":" + String(vll_avg, 2) + "," +
        "\"vll_ry\":"  + String(vll_ry, 2)  + "," +
        "\"vll_yb\":"  + String(vll_yb, 2)  + "," +
        "\"vll_br\":"  + String(vll_br, 2)  + "," +
        "\"cur_avg\":" + String(cur_avg, 2) + "," +
        "\"cur_r\":"   + String(cur_r, 2)   + "," +
        "\"cur_y\":"   + String(cur_y, 2)   + "," +
        "\"cur_b\":"   + String(cur_b, 2) +
        "}";

      int httpResponseCode = http.POST(payload);
      if (httpResponseCode == 200) {
        Serial.println("Uploaded to Shivam Cloud API.");
      } else {
        Serial.println("Upload failed. Code: " + String(httpResponseCode));
      }
      http.end();
    } else {
      Serial.println("Skipping upload due to read error or no Wi-Fi.");
    }
  }

  delay(3000);
}
