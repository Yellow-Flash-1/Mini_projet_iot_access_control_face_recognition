import json, csv
#import csv
import os
from flask import Flask, request, jsonify
from datetime import datetime
from deepface import DeepFace
from traceback import print_exc

app = Flask(__name__)

# Directory paths
KNOWN_FACES_DIR = "known_faces"
PERMISSIONS_FILE = "permissions.json"
HISTORY_DIR = "history"
LOG_FILE = f"{HISTORY_DIR}/essai.log"
ERROR_LOG = "app.log"


with open(PERMISSIONS_FILE) as f:
    KNOWN_PERSONS = json.load(f)


# API endpoint to handle image upload
@app.route('/recognize-face', methods=['POST'])
def recognize_face():
    if 'image' not in request.files:
        return jsonify({'error': 'No image found.'}), 400

    image = request.files['image']
    button = request.form.get('button')

    # Save the received image to history folder
    timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
    image_filename = f"{HISTORY_DIR}/{timestamp}_button{button}.jpg"
    image.save(image_filename)

    # Perform face recognition
    response = False
    log_data = [timestamp, button, response, "-"]
    for person, access in KNOWN_PERSONS.items():
        person_folder = f"{KNOWN_FACES_DIR}/{person}"
        face_recognizer = DeepFace.verify(image_filename, person_folder)
        if face_recognizer["verified"] and access[int(button)] == "1":
            log_data[3] = person
            response = True
            break

    # Save the log to the CSV file
    with open(LOG_FILE, mode='a', newline='') as file:
        writer = csv.writer(file)
        writer.writerow(log_data)

    return jsonify({'response': response}), 200


if __name__ == '__main__':
    with open(ERROR_LOG, mode='a') as f:
        try:
            app.run()
        
        except KeyboardInterrupt:
            print("server stopped with CTRL+C")
        except Exception as e:
            f.write(datetime.now().strftime("%Y%m%d%H%M%S")+"  ")
            print_exc(file=f)
