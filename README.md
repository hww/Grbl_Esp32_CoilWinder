# CoilWinder based on grbl for ESP32

This project implements a coil winding machine with an ESP32 SoC and two stepper motors.

The coil winder software is based on the Grbl [Grbl_ESP32](https://github.com/bdring/Grbl_Esp32) firmware and [Coilwinder](https://github.com/hoeken/Coilwinder) software.

Changes from the original Grbl firmware:

- coilwinder.h machine configuration with settings for two stepper motors.

- Report.cpp changed to support a (clunky) driver for an SSD1306 OLED display. The display shows the current CNC status, as in the image below:

<img src="https://github.com/hww/coil_winder_grbl_esp32/blob/main/doc/oled_display.jpg" width="300">

The coilgen folder contains a Python script to generage gcode from a coil's parameters. The gcode file
 includes a comment with the coil's turn and layer counts. This comment will be displayed on the OLED display.

The Grbl project provided a useful base to build upon. Thanks to Bdring for posting it! Thanks to Zach Hoeken for posting his python script.


<img src="https://github.com/hww/coil_winder_grbl_esp32/blob/main/doc/coil_winder_photo_1.jpg" width="900">

# The conclusion

I found GRBL ways is mostly not workable. Because the program asume how many turns will fit. But in reality happens "surprises". So i decided to make my custom firmware [DIY Coil Winder on ESP32](https://github.com/hww/coilwinder_esp32)

# ESP32 GPIO Functions   

The table below shows GPIO's functions.

| GPIO | Function |
|--------|--------------------------|
| GPIO02 | LED (1) |
| GPIO04 | Motor enable (active HI) |
| GPIO16 | Quad encoder A (2) |
| GPIO17 | Quad encoder B (2) |
| GPIO05 | SDCARD CS |
| GPIO18 | SDCARD SCK |
| GPIO19 | SDCARD MISO |
| GPIO21 | OLED SDA |
| GPIO22 | OLED SCK |
| GPIO23 | SDCARD MOSI |
| GPIO14 | DIR Y (active HI) |
| GPIO27 | STEP Y (active HI) |
| GPIO26 | DIR X (active HI) |
| GPIO25 | STEP X (active HI) |
| GPIO33 | BUTTON B |
| GPIO32 | BUTTON A (Quad encoder's button) (2) |
| GPIO35 | LIMIT X SWITCHER |

(1) The LED on the ESP32 starter kid board

(2) The quad encoder is not suported yed by the firmware. 
        
        
        

