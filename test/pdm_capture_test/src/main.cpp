#include <Arduino.h>
#include <Wire.h>

// NOP macros for the right amount of delay, empirically determined
#define NOP1 "nop\n\t"
#define NOP3 "nop\n\t""nop\n\t""nop\n\t"
#define NOP6 "nop\n\t""nop\n\t""nop\n\t""nop\n\t""nop\n\t""nop\n\t"
#define FOUR_MHZ __asm__(NOP6 NOP3 NOP1 NOP1)
#define TWO_MHZ __asm__(NOP6 NOP6 NOP6 NOP6 NOP6 NOP3)

// Vesper VM3011 defines
#define MIC_IIC_ADDR 0x60
#define MIC_PGA_REG 0x1
#define MIC_PGA_MIN_REG 0x3
#define MIC_PGA_MAX_REG 0x4
#define MIC_PGA_MIN_DEFAULT 0x40
#define MIC_PGA_MAX_DEFAULT 0x00

const int vad_pin = 31;
const int pdm_pin = 32;
const int clk_pin = 33;
const int led_pin = 13;  // Teensy 3.6 on board LED

const size_t buflen = 200000;  // most of the Teensy 3.6's 260kB RAM
                               // sufficient for 400ms of data at 4MHz
char buf[buflen];

FASTRUN void capture() {
    /* Capture 1600000 PDM samples. Samples are stored in the Teensy's RAM with
     * buf, and are written to serial after enough samples have been captured.
     */
    digitalWriteFast(led_pin, HIGH);
    long start = micros();
    char captured_byte = 0;
    char unused = 0;  // write to this byte to even out timing
    for (size_t i = 0; i < 8 * 8; i++) {  // skip the first 8 bytes; optional
        digitalWriteFast(clk_pin, HIGH);
        captured_byte |= digitalReadFast(pdm_pin) << (i % 8);
        // TWO_MHZ;
        FOUR_MHZ;
        digitalWriteFast(clk_pin, LOW);
        unused |= digitalReadFast(pdm_pin) << (i % 8);
        // TWO_MHZ;
        FOUR_MHZ;
    }
    captured_byte = 0;
    for (size_t i = 0; i < buflen * 8; i++) {
        digitalWriteFast(clk_pin, HIGH);
        captured_byte |= digitalReadFast(pdm_pin) << (i % 8);
        // TWO_MHZ;
        FOUR_MHZ;
        digitalWriteFast(clk_pin, LOW);
        unused |= digitalReadFast(pdm_pin) << (i % 8);
        // TWO_MHZ;
        FOUR_MHZ;
        buf[i >> 3] = captured_byte;  // always store byte, overwriting each
                                      // time to keep constistent sample rate
        if (i % 8 == 7) captured_byte = 0;
    }
    long end = micros();
    digitalWriteFast(led_pin, LOW);
    Serial.write(buf, buflen);
    // Serial.print("\nElapsed time (ms): ");  // use this to determine proper
                                               // NOP delays
    // Serial.println((end - start) / 1000.0);
}

void write_pga_min_gain() {
    /* Write the minimum threshold for the microphone's PGA gain.
     */
    Wire.beginTransmission(MIC_IIC_ADDR);
    char val = MIC_PGA_MIN_DEFAULT | 0x1f;  // max gain
    Wire.write(MIC_PGA_MIN_REG);
    Wire.write(val);
    Wire.endTransmission();
}

void write_pga_max_gain() {
    /* Write the maximum threshold for the microphone's PGA gain.
     */
    Wire.beginTransmission(MIC_IIC_ADDR);
    char val = MIC_PGA_MAX_DEFAULT | 0x1f;  // max gain
    Wire.write(MIC_PGA_MAX_REG);
    Wire.write(val);
    Wire.endTransmission();
}

void read_pga_min_gain() {
    /* Read back the minimum threshold for the microphone's PGA gain.
     */
    Wire.beginTransmission(MIC_IIC_ADDR);
    Wire.write(MIC_PGA_MIN_REG);
    Wire.endTransmission(false);  // no stop condition
    Wire.requestFrom(MIC_IIC_ADDR, 1);
    char val = Wire.read();
    Serial.print("PGA min gain: ");
    Serial.println(val, HEX);
}

void read_pga_max_gain() {
    /* Read back the maximum threshold for the microphone's PGA gain.
     */
    Wire.beginTransmission(MIC_IIC_ADDR);
    Wire.write(MIC_PGA_MAX_REG);
    Wire.endTransmission(false);  // no stop condition
    Wire.requestFrom(MIC_IIC_ADDR, 1);
    char val = Wire.read();
    Serial.print("PGA max gain: ");
    Serial.println(val, HEX);
}

void read_pga_gain() {
    /* Read the current state of the microphone's PGA gain.
     */
    Wire.beginTransmission(MIC_IIC_ADDR);
    Wire.write(MIC_PGA_REG);
    Wire.endTransmission(false);  // no stop condition
    Wire.requestFrom(MIC_IIC_ADDR, 1);
    char val = Wire.read();
    Serial.print("Received: ");
    Serial.println(val, HEX);
}

void setup() {
    Serial.begin(0);  // baud rate argument is ignored
    while (!Serial);  // wait for monitor to open
    pinMode(vad_pin, INPUT);
    pinMode(clk_pin, OUTPUT);
    pinMode(pdm_pin, INPUT);
    pinMode(led_pin, OUTPUT);
    cli();  // disable interrupts for more exact timing

    // Wire.begin();  // write gains and check readback
    // read_pga_min_gain();
    // read_pga_max_gain();
    // write_pga_min_gain();
    // write_pga_max_gain();
    // read_pga_min_gain();
    // read_pga_max_gain();

    // Serial.print("F_CPU ");  // Check the CPU clock frequency
    // Serial.println(F_CPU);
}

void loop() {
    // delay(50);  // wait for VAD pin to reset
    // while (!digitalRead(vad_pin)) {}  // wait for VAD to go high
    capture();
}
