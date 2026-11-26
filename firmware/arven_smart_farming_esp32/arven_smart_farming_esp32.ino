#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include <DHT.h>
#include <time.h>

// 1. KONFIGURASI WI-FI dan FIREBASE
const char* WIFI_SSID     = "MHS-PNM";       
const char* WIFI_PASSWORD = "sustainability";   

const char* FIREBASE_HOST = "https://arven-iot-default-rtdb.asia-southeast1.firebasedatabase.app";
const char* DEVICE_ID     = "arven_device_01";

// Database Secret / Auth Token (opsional)
const char* FIREBASE_AUTH = "";

// 2. MAPPING PIN HARDWARE
#define PIN_SOIL_ANALOG    34   // Sensor Kelembapan Tanah
#define PIN_DHT            4    // Sensor Suhu dan Kelembapan Udara DHT22
#define PIN_RAIN_DIGITAL   32   // Sensor Hujan Digital
#define PIN_RELAY_PUMP     26   // Modul Relay Pompa Air 12V 
#define PIN_STATUS_LED     2    // LED Indikator Pompa 

#define DHT_TYPE           DHT22
DHT dht(PIN_DHT, DHT_TYPE);

// Kalibrasi ADC Kelembapan Tanah
const int AIR_VALUE   = 3500;  // Nilai ADC saat probe kering di udara (0%)
const int WATER_VALUE = 1400;  // Nilai ADC saat probe tercelup air (100%)

// Logika Output ESP32 via Driver Transistor NPN (BC547 / 2N2222 / S8050) ke Relay 12V Active-LOW:
// GPIO 26 HIGH (3.3V) -> Transistor ON -> Pin IN Relay ditarik ke GND -> Pompa Menyala
// GPIO 26 LOW  (0V)   -> Transistor OFF -> Pin IN Relay putus dari GND -> Pompa Mati
const int RELAY_ON  = HIGH;
const int RELAY_OFF = LOW;

// 3. STRUKTUR DATA dan PARAMETER SISTEM
struct DeviceSettings {
  int moistureThreshold       = 40;   // Batas min pompa ON (%)
  int moistureThresholdMax    = 85;   // Target max pompa OFF (%)
  int wateringDurationSec     = 15;   // Cadangan durasi default
  int soakIntervalMin         = 20;   // Jeda peresapan air (menit, legacy)
  int soakIntervalSec         = 1200; // Jeda peresapan air (detik)
  float maxTemperatureLimit   = 35.0; // Batas suhu ekstrem
  bool rainDelayEnabled       = true; // Proteksi hujan
  int manualSafetyTimeoutMin  = 5;    // Batas pengaman auto cut-off mode manual (menit, legacy)
  int manualSafetyTimeoutSec  = 300;  // Batas pengaman auto cut-off mode manual (detik)
  int scheduleFrequency       = 2;    // 2, 3, atau 4 kali sehari
  String time1                = "07:00";
  String time2                = "16:30";
  String time3                = "12:00";
  String time4                = "20:00";
  int scheduleDurationSec     = 20;   // Durasi siram terjadwal
} deviceSettings;

struct SensorReadings {
  float soilMoisture = 0.0;
  float temperature  = 0.0;
  float humidity     = 0.0;
  bool isRaining     = false;
  int rawSoilAdc     = 0;
  bool dhtError      = false;
} currentSensors;

String activeMode        = "auto_moisture"; // 'auto_moisture', 'scheduled', 'manual'
String previousMode      = "auto_moisture";
bool manualPumpCommand   = false;
bool isPumpActive        = false;

unsigned long pumpStartTime         = 0;
unsigned long pumpDurationLimit     = 0;
unsigned long lastSoakTimestamp     = 0;
bool hasFinishedAutoCycle           = false;
float pumpStartSoilMoisture         = 0.0;

unsigned long lastFetchTime         = 0;
unsigned long lastSensorSyncTime    = 0;
unsigned long lastSensorLogTime     = 0;
unsigned long lastHeartbeatTime     = 0;

// NTP Server untuk Waktu Indonesia Barat
const char* NTP_SERVER         = "pool.ntp.org";
const long  GMT_OFFSET_SEC     = 25200;
const int   DAYLIGHT_OFFSET_SEC = 0;

// 4. PROTOTYPE FUNGSI
void connectWiFi();
void syncNtpTime();
void readSensors();
void updatePumpState(bool active, const String& modeTrigger, int durationSec);
void logIrrigationHistoryToFirebase(const String& mode, int durationSec, float soilBefore, float soilAfter);
void resetManualCommandInFirebase();
void processIrrigationLogic();
void checkScheduledIrrigation();
void sendTelemetryToFirebase();
void sendSensorLogToFirebase();
void sendHeartbeatToFirebase();
void fetchControlAndSettingsFromFirebase();
bool getFormattedCurrentTime(String& outTime);
uint64_t getEpochTimeMs();

// 5. SETUP
void setup() {
  Serial.begin(115200);
  delay(1000);
  Serial.println("\n=============================================");
  Serial.println("  ARVEN SMART FARMING - ESP32 FIRMWARE v2.1  ");
  Serial.println("=============================================");

  pinMode(PIN_RELAY_PUMP, OUTPUT);
  digitalWrite(PIN_RELAY_PUMP, RELAY_OFF); // Pastikan pompa mati saat awal boot

  pinMode(PIN_STATUS_LED, OUTPUT);
  digitalWrite(PIN_STATUS_LED, LOW);

  pinMode(PIN_RAIN_DIGITAL, INPUT_PULLUP);
  analogReadResolution(12);

  dht.begin();
  connectWiFi();
  syncNtpTime();

  // Sinkronisasi pengaturan awal dari Firebase
  fetchControlAndSettingsFromFirebase();
  previousMode = activeMode;

  // Baca sensor dan kirim status pertama
  readSensors();
  sendTelemetryToFirebase();
  sendSensorLogToFirebase();
  sendHeartbeatToFirebase();

  // Sinkronkan status awal pompa ke Firebase (pastikan OFF saat boot)
  updatePumpState(false, "boot", 0);

  Serial.println("[SYSTEM] Inisialisasi selesai. Sistem irigasi siap beroperasi.\n");
}

// 6. MAIN LOOP
void loop() {
  if (WiFi.status() != WL_CONNECTED) {
    connectWiFi();
  }

  // 1. Baca semua sensor lingkungan
  readSensors();

  // 2. Jalankan logika kontrol irigasi (Manual / Terjadwal / Otomatis Min-Max)
  processIrrigationLogic();

  // 3. Tarik perintah kontrol dan pengaturan terbaru dari Firebase tiap 2.5 detik
  if (millis() - lastFetchTime >= 2500) {
    lastFetchTime = millis();
    fetchControlAndSettingsFromFirebase();
  }

  // 4. Kirim data pembacaan sensor ke Firebase tiap 5 detik
  if (millis() - lastSensorSyncTime >= 5000) {
    lastSensorSyncTime = millis();
    sendTelemetryToFirebase();
  }

  // 5. Catat snapshot historis grafik sensor tiap 2 menit (idempoten per menit)
  if (millis() - lastSensorLogTime >= 120000) {
    lastSensorLogTime = millis();
    sendSensorLogToFirebase();
  }

  // 6. Kirim Heartbeat status online tiap 15 detik
  if (millis() - lastHeartbeatTime >= 15000) {
    lastHeartbeatTime = millis();
    sendHeartbeatToFirebase();
  }

  delay(200);
}

// 7. LOGIKA KONTROL IRIGASI
void processIrrigationLogic() {
  // Pengaman saat perpindahan mode operasional: matikan pompa supaya tidak nyangkut
  if (activeMode != previousMode) {
    Serial.printf("[MODE] Mode berubah dari '%s' ke '%s'.\n", previousMode.c_str(), activeMode.c_str());
    if (isPumpActive) {
      int elapsedSec = (millis() - pumpStartTime) / 1000;
      updatePumpState(false, previousMode, elapsedSec);
    }
    if (previousMode == "manual" && manualPumpCommand) {
      manualPumpCommand = false;
      resetManualCommandInFirebase();
    }
    previousMode = activeMode;
  }

  // A. MODE MANUAL (Bebas waktu + Pengaman Auto Cut-Off jika operator lupa)
  if (activeMode == "manual") {
    if (manualPumpCommand && !isPumpActive) {
      Serial.println("[MANUAL] Instruksi NYALAKAN pompa diterima dari aplikasi.");
      updatePumpState(true, "manual", 0);
    } else if (!manualPumpCommand && isPumpActive) {
      int elapsedSec = (millis() - pumpStartTime) / 1000;
      Serial.printf("[MANUAL] Instruksi HENTIKAN pompa diterima (Durasi: %d detik).\n", elapsedSec);
      updatePumpState(false, "manual", elapsedSec);
    }

    // Pengaman Auto Cut-Off: mati otomatis jika melebihi batas waktu detik/menit yang diatur
    if (isPumpActive) {
      unsigned long safetyLimitMs = (unsigned long)deviceSettings.manualSafetyTimeoutSec * 1000UL;
      if (millis() - pumpStartTime >= safetyLimitMs) {
        int elapsedSec = (millis() - pumpStartTime) / 1000;
        Serial.printf("[PENGAMAN] Pompa manual melampaui batas %d detik! Auto cut-off aktif.\n",
                      deviceSettings.manualSafetyTimeoutSec);
        updatePumpState(false, "manual_auto_cutoff", elapsedSec);
        manualPumpCommand = false;
        resetManualCommandInFirebase();
      }
    }
    return;
  }

  // Proteksi Hujan (Rain Delay) berlaku untuk Mode Otomatis & Mode Terjadwal
  if (currentSensors.isRaining && deviceSettings.rainDelayEnabled) {
    if (isPumpActive) {
      int elapsedSec = (millis() - pumpStartTime) / 1000;
      Serial.println("[PROTEKSI HUJAN] Air hujan terdeteksi! Menghentikan penyiraman otomatis/jadwal.");
      updatePumpState(false, activeMode, elapsedSec);
    }
    return; // Jangan mulai penyiraman selama hujan masih turun
  }

  // B. MODE TERJADWAL
  if (activeMode == "scheduled") {
    if (isPumpActive) {
      if (millis() - pumpStartTime >= pumpDurationLimit) {
        int elapsedSec = (millis() - pumpStartTime) / 1000;
        Serial.printf("[JADWAL] Durasi penyiraman terjadwal (%d detik) selesai. Pompa OFF.\n", elapsedSec);
        updatePumpState(false, "scheduled", elapsedSec);
      }
    } else {
      checkScheduledIrrigation();
    }
    return;
  }

  // C. MODE OTOMATIS 
  if (activeMode == "auto_moisture") {
    bool inSoakPeriod = hasFinishedAutoCycle &&
                        ((millis() - lastSoakTimestamp) < ((unsigned long)deviceSettings.soakIntervalSec * 1000UL));

    // 1. Pemicu ON: Kelembapan tanah <= ambang minimum
    if (!isPumpActive && !inSoakPeriod) {
      if (currentSensors.soilMoisture <= (float)deviceSettings.moistureThreshold) {
        Serial.printf("[AUTO] Kelembapan %.1f%% <= batas minimum %d%%! Menyalakan pompa...\n",
                      currentSensors.soilMoisture, deviceSettings.moistureThreshold);
        updatePumpState(true, "auto_moisture", 0);
      }
    }

    // 2. Pemicu OFF: Kelembapan tanah >= target maksimum
    if (isPumpActive) {
      if (currentSensors.soilMoisture >= (float)deviceSettings.moistureThresholdMax) {
        int elapsedSec = (millis() - pumpStartTime) / 1000;
        Serial.printf("[AUTO] Kelembapan %.1f%% >= target maksimum %d%%! Mematikan pompa (Durasi: %d detik).\n",
                      currentSensors.soilMoisture, deviceSettings.moistureThresholdMax, elapsedSec);
        updatePumpState(false, "auto_moisture", elapsedSec);
        lastSoakTimestamp = millis();
        hasFinishedAutoCycle = true;
      }
    }
  }
}

void checkScheduledIrrigation() {
  if (isPumpActive) return;

  String currentTime;
  if (!getFormattedCurrentTime(currentTime)) {
    // Waktu NTP belum sinkron, tunda eksekusi jadwal agar tidak salah picu
    return;
  }

  static String lastExecutedTime = "";
  if (currentTime == lastExecutedTime) return;

  bool shouldWater = false;
  if (currentTime == deviceSettings.time1) shouldWater = true;
  if (currentTime == deviceSettings.time2) shouldWater = true;
  if (deviceSettings.scheduleFrequency == 3 && currentTime == deviceSettings.time3) shouldWater = true;

  if (shouldWater) {
    lastExecutedTime = currentTime;
    pumpDurationLimit = (unsigned long)deviceSettings.scheduleDurationSec * 1000UL;
    Serial.printf("[JADWAL] Jam %s tercapai. Memulai irigasi selama %d detik.\n",
                  currentTime.c_str(), deviceSettings.scheduleDurationSec);
    updatePumpState(true, "scheduled", deviceSettings.scheduleDurationSec);
  }
}

void updatePumpState(bool active, const String& modeTrigger, int durationSec) {
  bool wasActive = isPumpActive;
  isPumpActive = active;
  digitalWrite(PIN_RELAY_PUMP, active ? RELAY_ON : RELAY_OFF);
  digitalWrite(PIN_STATUS_LED, active ? HIGH : LOW);

  if (active) {
    pumpStartTime = millis();
    pumpStartSoilMoisture = currentSensors.soilMoisture;
  }

  if (WiFi.status() == WL_CONNECTED) {
    WiFiClientSecure client;
    client.setInsecure();
    HTTPClient http;

    String url = String(FIREBASE_HOST) + "/devices/" + DEVICE_ID + "/pump_state.json";
    if (strlen(FIREBASE_AUTH) > 0) url += "?auth=" + String(FIREBASE_AUTH);

    http.begin(client, url);
    http.addHeader("Content-Type", "application/json");

    StaticJsonDocument<256> doc;
    doc["active"]            = isPumpActive;
    doc["current_mode"]      = modeTrigger;
    doc["last_started"]      = active ? getEpochTimeMs() : 0;
    doc["last_duration_sec"] = durationSec;

    String jsonPayload;
    serializeJson(doc, jsonPayload);

    http.PUT(jsonPayload);
    http.end();

    // Catat log riwayat ke Firebase saat pompa berhenti menyiram
    if (wasActive && !active && durationSec > 0) {
      logIrrigationHistoryToFirebase(modeTrigger, durationSec, pumpStartSoilMoisture, currentSensors.soilMoisture);
    }
  }
}

void logIrrigationHistoryToFirebase(const String& mode, int durationSec, float soilBefore, float soilAfter) {
  if (WiFi.status() != WL_CONNECTED) return;

  WiFiClientSecure client;
  client.setInsecure();
  HTTPClient http;

  String url = String(FIREBASE_HOST) + "/devices/" + DEVICE_ID + "/history.json";
  if (strlen(FIREBASE_AUTH) > 0) url += "?auth=" + String(FIREBASE_AUTH);

  http.begin(client, url);
  http.addHeader("Content-Type", "application/json");

  // Pompa mini 600 L/jam = 0.1667 L/detik
  float waterLiters = (float)durationSec * (600.0 / 3600.0);

  String title = "Penyiraman Otomatis";
  String status = "Selesai";
  if (mode == "scheduled") {
    title = "Penyiraman Terjadwal";
  } else if (mode == "manual") {
    title = "Penyiraman Manual";
    status = "Dihentikan Manual";
  } else if (mode == "manual_auto_cutoff") {
    title = "Penyiraman Manual";
    status = "Auto Cut-Off";
  }

  StaticJsonDocument<256> doc;
  doc["timestamp"]    = getEpochTimeMs();
  doc["title"]        = title;
  doc["mode"]         = mode;
  doc["duration_sec"] = durationSec;
  doc["water_liters"] = serialized(String(waterLiters, 2));
  doc["soil_before"]  = serialized(String(soilBefore, 1));
  doc["soil_after"]   = serialized(String(soilAfter, 1));
  doc["status"]       = status;

  String jsonPayload;
  serializeJson(doc, jsonPayload);

  int httpCode = http.POST(jsonPayload);
  if (httpCode > 0) {
    Serial.printf("[HISTORY] Log penyiraman (%s, %d dtk, %.2f L) berhasil disimpan ke Firebase.\n",
                  title.c_str(), durationSec, waterLiters);
  }
  http.end();
}

void resetManualCommandInFirebase() {
  if (WiFi.status() != WL_CONNECTED) return;

  WiFiClientSecure client;
  client.setInsecure();
  HTTPClient http;

  String url = String(FIREBASE_HOST) + "/devices/" + DEVICE_ID + "/control/pump_manual_command.json";
  if (strlen(FIREBASE_AUTH) > 0) url += "?auth=" + String(FIREBASE_AUTH);

  http.begin(client, url);
  http.addHeader("Content-Type", "application/json");
  http.PUT("false");
  http.end();
}

// 8. PEMBACAAN SENSOR FISIK
void readSensors() {
  // 1. Kelembapan Tanah Analog
  long totalRaw = 0;
  for (int i = 0; i < 5; i++) {
    totalRaw += analogRead(PIN_SOIL_ANALOG);
    delay(5);
  }
  int rawSoil = totalRaw / 5;
  currentSensors.rawSoilAdc = rawSoil;
  int percent = map(rawSoil, AIR_VALUE, WATER_VALUE, 0, 100);
  currentSensors.soilMoisture = constrain((float)percent, 0.0, 100.0);

  // 2. DHT22 Suhu dan Kelembapan Udara (dibaca max tiap 2 detik sesuai spesifikasi DHT22)
  static unsigned long lastDhtRead = 0;
  if (millis() - lastDhtRead >= 2000 || lastDhtRead == 0) {
    lastDhtRead = millis();
    float t = dht.readTemperature();
    float h = dht.readHumidity();
    if (isnan(t) || isnan(h)) {
      currentSensors.dhtError = true;
    } else {
      currentSensors.dhtError = false;
      currentSensors.temperature = t;
      currentSensors.humidity = h;
    }
  }

  // 3. Sensor Hujan Digital (LOW = Air hujan terdeteksi di papan PCB)
  currentSensors.isRaining = (digitalRead(PIN_RAIN_DIGITAL) == LOW);
}

// 9. KOMUNIKASI DATABASE FIREBASE (REST HTTPS)
void sendTelemetryToFirebase() {
  if (WiFi.status() != WL_CONNECTED) return;

  WiFiClientSecure client;
  client.setInsecure();
  HTTPClient http;

  String url = String(FIREBASE_HOST) + "/devices/" + DEVICE_ID + "/sensors.json";
  if (strlen(FIREBASE_AUTH) > 0) url += "?auth=" + String(FIREBASE_AUTH);

  http.begin(client, url);
  http.addHeader("Content-Type", "application/json");

  StaticJsonDocument<256> doc;
  doc["soil_moisture"] = round(currentSensors.soilMoisture * 10.0) / 10.0;
  doc["temperature"]   = round(currentSensors.temperature * 10.0) / 10.0;
  doc["humidity"]      = round(currentSensors.humidity * 10.0) / 10.0;
  doc["rain"]          = currentSensors.isRaining;
  doc["updated_at"]    = getEpochTimeMs();

  String payload;
  serializeJson(doc, payload);

  int code = http.PUT(payload);
  if (code > 0) {
    Serial.printf("[SYNC] Tanah: %.1f%% (RawADC: %d) | Suhu: %.1fC | Udara: %.1f%% (DHT: %s) | Hujan: %s\n",
                  currentSensors.soilMoisture, currentSensors.rawSoilAdc,
                  currentSensors.temperature, currentSensors.humidity,
                  currentSensors.dhtError ? "ERR/NaN" : "OK",
                  currentSensors.isRaining ? "YA" : "TIDAK");
  } else {
    Serial.printf("[SYNC GAGAL] HTTP Code: %d\n", code);
  }
  http.end();
}

void sendSensorLogToFirebase() {
  if (WiFi.status() != WL_CONNECTED) return;

  time_t now;
  time(&now);
  if (now <= 1700000000) return; // Tunggu NTP valid agar riwayat grafik akurat

  unsigned long epochMin = (unsigned long)(now / 60);
  char keyBuf[16];
  sprintf(keyBuf, "m_%010lu", epochMin);
  uint64_t bucketMs = (uint64_t)epochMin * 60000ULL;

  WiFiClientSecure client;
  client.setInsecure();
  HTTPClient http;

  String url = String(FIREBASE_HOST) + "/devices/" + DEVICE_ID + "/sensor_logs/" + String(keyBuf) + ".json";
  if (strlen(FIREBASE_AUTH) > 0) url += "?auth=" + String(FIREBASE_AUTH);

  http.begin(client, url);
  http.addHeader("Content-Type", "application/json");

  StaticJsonDocument<256> doc;
  doc["timestamp"]     = bucketMs;
  doc["soil_moisture"] = round(currentSensors.soilMoisture * 10.0) / 10.0;
  doc["temperature"]   = round(currentSensors.temperature * 10.0) / 10.0;
  doc["humidity"]      = round(currentSensors.humidity * 10.0) / 10.0;
  doc["rain"]          = currentSensors.isRaining;

  String payload;
  serializeJson(doc, payload);

  int code = http.PUT(payload);
  if (code > 0) {
    Serial.printf("[SENSOR_LOG] Snapshot %s tersimpan (HTTP %d).\n", keyBuf, code);
  }
  http.end();

  // Simpan juga ringkasan per jam sekali setiap jam untuk grafik 3 hari - 30 hari
  static unsigned long lastLoggedHour = 0;
  unsigned long epochHour = (unsigned long)(now / 3600);
  if (epochHour != lastLoggedHour) {
    lastLoggedHour = epochHour;
    char hourKey[16];
    sprintf(hourKey, "h_%08lu", epochHour);
    uint64_t hourMs = (uint64_t)epochHour * 3600000ULL;

    String hourUrl = String(FIREBASE_HOST) + "/devices/" + DEVICE_ID + "/sensor_logs_hourly/" + String(hourKey) + ".json";
    if (strlen(FIREBASE_AUTH) > 0) hourUrl += "?auth=" + String(FIREBASE_AUTH);

    http.begin(client, hourUrl);
    http.addHeader("Content-Type", "application/json");

    StaticJsonDocument<256> hourDoc;
    hourDoc["timestamp"]     = hourMs;
    hourDoc["soil_moisture"] = round(currentSensors.soilMoisture * 10.0) / 10.0;
    hourDoc["temperature"]   = round(currentSensors.temperature * 10.0) / 10.0;
    hourDoc["humidity"]      = round(currentSensors.humidity * 10.0) / 10.0;
    hourDoc["rain"]          = currentSensors.isRaining;

    String hourPayload;
    serializeJson(hourDoc, hourPayload);
    http.PUT(hourPayload);
    http.end();
  }
}

void sendHeartbeatToFirebase() {
  if (WiFi.status() != WL_CONNECTED) return;

  WiFiClientSecure client;
  client.setInsecure();
  HTTPClient http;

  String url = String(FIREBASE_HOST) + "/devices/" + DEVICE_ID + "/status.json";
  if (strlen(FIREBASE_AUTH) > 0) url += "?auth=" + String(FIREBASE_AUTH);

  http.begin(client, url);
  http.addHeader("Content-Type", "application/json");

  StaticJsonDocument<128> doc;
  doc["online"]    = true;
  doc["last_seen"] = getEpochTimeMs();

  String payload;
  serializeJson(doc, payload);

  http.PUT(payload);
  http.end();
}

void fetchControlAndSettingsFromFirebase() {
  if (WiFi.status() != WL_CONNECTED) return;

  WiFiClientSecure client;
  client.setInsecure();
  HTTPClient http;

  // A. Tarik Perintah Kontrol
  String urlControl = String(FIREBASE_HOST) + "/devices/" + DEVICE_ID + "/control.json";
  if (strlen(FIREBASE_AUTH) > 0) urlControl += "?auth=" + String(FIREBASE_AUTH);

  http.begin(client, urlControl);
  if (http.GET() == 200) {
    String payload = http.getString();
    StaticJsonDocument<256> doc;
    if (!deserializeJson(doc, payload)) {
      if (!doc["mode"].isNull()) {
        activeMode = doc["mode"].as<String>();
      }
      if (!doc["pump_manual_command"].isNull()) {
        manualPumpCommand = doc["pump_manual_command"].as<bool>();
      }
    }
  }
  http.end();

  // B. Tarik Parameter Settings dan Jadwal Terbaru
  String urlSettings = String(FIREBASE_HOST) + "/devices/" + DEVICE_ID + "/settings.json";
  if (strlen(FIREBASE_AUTH) > 0) urlSettings += "?auth=" + String(FIREBASE_AUTH);

  http.begin(client, urlSettings);
  if (http.GET() == 200) {
    String payload = http.getString();
    StaticJsonDocument<768> doc;
    if (!deserializeJson(doc, payload)) {
      if (!doc["moisture_threshold"].isNull()) {
        deviceSettings.moistureThreshold = doc["moisture_threshold"].as<int>();
      }
      if (!doc["moisture_threshold_max"].isNull()) {
        deviceSettings.moistureThresholdMax = doc["moisture_threshold_max"].as<int>();
      }
      if (!doc["watering_duration_sec"].isNull()) {
        deviceSettings.wateringDurationSec = doc["watering_duration_sec"].as<int>();
      }
      if (!doc["soak_interval_sec"].isNull()) {
        deviceSettings.soakIntervalSec = doc["soak_interval_sec"].as<int>();
        deviceSettings.soakIntervalMin = max(1, deviceSettings.soakIntervalSec / 60);
      } else if (!doc["soak_interval_min"].isNull()) {
        deviceSettings.soakIntervalMin = doc["soak_interval_min"].as<int>();
        deviceSettings.soakIntervalSec = deviceSettings.soakIntervalMin * 60;
      }
      if (!doc["rain_delay_enabled"].isNull()) {
        deviceSettings.rainDelayEnabled = doc["rain_delay_enabled"].as<bool>();
      }
      if (!doc["manual_safety_timeout_sec"].isNull()) {
        deviceSettings.manualSafetyTimeoutSec = doc["manual_safety_timeout_sec"].as<int>();
        deviceSettings.manualSafetyTimeoutMin = max(1, deviceSettings.manualSafetyTimeoutSec / 60);
      } else if (!doc["manual_safety_timeout_min"].isNull()) {
        deviceSettings.manualSafetyTimeoutMin = doc["manual_safety_timeout_min"].as<int>();
        deviceSettings.manualSafetyTimeoutSec = deviceSettings.manualSafetyTimeoutMin * 60;
      }
      if (!doc["schedule"].isNull()) {
        JsonObject sch = doc["schedule"];
        deviceSettings.scheduleFrequency   = sch["frequency"] | 2;
        deviceSettings.time1               = sch["time_1"] | "07:00";
        deviceSettings.time2               = sch["time_2"] | "16:30";
        deviceSettings.time3               = sch["time_3"] | "12:00";
        deviceSettings.time4               = sch["time_4"] | "20:00";
        deviceSettings.scheduleDurationSec = sch["duration_sec"] | 20;
      }
    }
  }
  http.end();
}

// 10. UTILITAS KONEKSI & WAKTU
void connectWiFi() {
  if (WiFi.status() == WL_CONNECTED) return;

  Serial.printf("[WIFI] Menghubungkan ke %s ", WIFI_SSID);
  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

  int attempt = 0;
  while (WiFi.status() != WL_CONNECTED && attempt < 25) {
    delay(500);
    Serial.print(".");
    attempt++;
  }

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\n[WIFI] Terhubung! IP: " + WiFi.localIP().toString());
  } else {
    Serial.println("\n[WIFI] Gagal terhubung. Akan dicoba lagi pada loop berikutnya.");
  }
}

void syncNtpTime() {
  configTime(GMT_OFFSET_SEC, DAYLIGHT_OFFSET_SEC, NTP_SERVER);
  struct tm timeinfo;
  if (getLocalTime(&timeinfo, 5000)) {
    Serial.printf("[NTP] Waktu sinkron: %02d:%02d:%02d WIB\n",
                  timeinfo.tm_hour, timeinfo.tm_min, timeinfo.tm_sec);
  } else {
    Serial.println("[NTP] Sinkronisasi waktu tertunda, akan dicoba otomatis di background.");
  }
}

bool getFormattedCurrentTime(String& outTime) {
  struct tm timeinfo;
  if (!getLocalTime(&timeinfo, 10)) {
    return false;
  }
  char str[6];
  sprintf(str, "%02d:%02d", timeinfo.tm_hour, timeinfo.tm_min);
  outTime = String(str);
  return true;
}

uint64_t getEpochTimeMs() {
  time_t now;
  time(&now);
  if (now > 1700000000) {
    return (uint64_t)now * 1000ULL;
  }
  return (uint64_t)millis();
}
