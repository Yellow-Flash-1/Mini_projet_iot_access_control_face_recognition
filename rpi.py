import requests
import RPi.GPIO as GPIO
import time
from picamera import PiCamera

GPIO.setmode(GPIO.BCM)
GPIO.setup(, GPIO.IN)  # Button 1
GPIO.setup(, GPIO.IN)  # Button 2
GPIO.setup(, GPIO.OUT)  # LED vert
GPIO.setup(, GPIO.OUT)  # LED rouge

camera = PiCamera()

API_URL = ""

def capture_and_send_image(button_num):
    image_path = f"img.jpg"
    camera.capture(image_path)
    
    with open(image_path, "rb") as image_file:
        file = {"image": image_file}
        data = {"button": button_num}
        response = requests.post(API_URL, files=file, data=data)
    
    if response.status_code == 200:
        is_face_recognized = response.json()["is_face_recognized"]
        if is_face_recognized:
            GPIO.output(, GPIO.HIGH)  # LED vert
            GPIO.output(, GPIO.LOW)  # LED rouge
        else:
            GPIO.output(, GPIO.LOW)  # LED vert
            GPIO.output(, GPIO.HIGH)  # LED rouge
    
    os.remove(image_path)


def button1_callback(channel):
    print("Button 1 pressed")
    capture_and_send_image(1)

def button2_callback(channel):
    print("Button 2 pressed")
    capture_and_send_image(2)


GPIO.add_event_detect(18, GPIO.RISING, callback=button1_callback, bouncetime=200)
GPIO.add_event_detect(23, GPIO.RISING, callback=button2_callback, bouncetime=200)


try:
    while True:
        time.sleep(0.1)

except KeyboardInterrupt:
    GPIO.cleanup()
