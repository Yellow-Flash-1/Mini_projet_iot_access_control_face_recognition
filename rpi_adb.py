import requests
import RPi.GPIO as GPIO
from datetime import datetime
from time import sleep
from traceback import print_exc
import os
"""layout pins
               3V3  (1) (2)  5V    
             GPIO2  (3) (4)  5V    
    B1 -->   GPIO3  (5) (6)  GND   
    R1 -->   GPIO4  (7) (8)  GPIO14 <--  V1
               GND  (9) (10) GPIO15 <--  B2
    R2 -->  GPIO17 (11) (12) GPIO18 <--  V2
    B3 -->  GPIO27 (13) (14) GND   
    R3 -->  GPIO22 (15) (16) GPIO23 <--  V3
               3V3 (17) (18) GPIO24
            GPIO10 (19) (20) GND   
             GPIO9 (21) (22) GPIO25
            GPIO11 (23) (24) GPIO8 
               GND (25) (26) GPIO7 
             GPIO0 (27) (28) GPIO1 
             GPIO5 (29) (30) GND   
             GPIO6 (31) (32) GPIO12
            GPIO13 (33) (34) GND   
            GPIO19 (35) (36) GPIO16
            GPIO26 (37) (38) GPIO20
               GND (39) (40) GPIO21
"""
GPIO.setmode(GPIO.BCM)



Pins = {# B :[R, V]
    5  :[7 ,8],
    10 :[11 ,12],
    13 :[15 ,16]
}


API_URL = ""

def capture_and_send_image(n):
    image_path = "img.jpg"
    makePic(image_path)

    with open(image_path, "rb") as image_file:
        file = {"image": image_file}
        data = {"button": n}
        response = requests.post(API_URL, files=file, data=data, timeout=1000)

    if response.status_code == 200:
        is_face_recognized = response.json()["is_face_recognized"]
        GPIO.output(Pins[n][is_face_recognized], GPIO.HIGH)  # LED corr
        # GPIO.output(Pins[n][not is_face_recognized], GPIO.LOW)  # LED autre
        sleep(.5)
        GPIO.output(Pins[n][is_face_recognized], GPIO.LOW)

#    os.remove(image_path)

def makePic(path):
    os.system("adb shell mkdir /sdcard/camera")
    os.system(f"adb shell am start -a android.media.action.IMAGE_CAPTURE -t image/jpeg -d /sdcard/camera/{path}")
    os.system(f"adb pull /sdcard/camera/{path}")



def button_callback(channel):
    button_number = Pins.keys().index(channel)
    print(f"Button {button_number} pressed")
    capture_and_send_image(button_number)


for button,leds in Pins.items():
    GPIO.setup(button, GPIO.IN)
    GPIO.setup(leds, GPIO.OUT)
    GPIO.add_event_detect(button, GPIO.RISING, callback=button_callback)


ERROR_LOG = "card.log"
with open(ERROR_LOG, mode='a') as f:
    try:
        while True:
            sleep(.5)
    except KeyboardInterrupt:
        print("KeyboardInterrupt")
    except Exception as e:
        f.write(datetime.now().strftime("%Y%m%d%H%M%S")+"  ")
        print_exc(file=f)

    finally:
        GPIO.cleanup()
