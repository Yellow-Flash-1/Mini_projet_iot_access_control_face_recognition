import json
import sqlite3
import base64
import os
from flask import Flask, request, jsonify, send_file
from datetime import datetime
from deepface import DeepFace
from traceback import print_exc
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

# Directory paths
KNOWN_FACES_DIR = "known_faces"
PERMISSIONS_FILE = "permissions.json"
HISTORY_DIR = "history"
LOG_FILE = "attempts.db"
ERROR_LOG = "app.log"


def get_connection():
    conn = sqlite3.connect(LOG_FILE)
    conn.execute(
        '''
        CREATE TABLE IF NOT EXISTS logs (
            timestamp TEXT,
            button INTEGER,
            response INTEGER,
            person TEXT
        )
        '''
    )
    conn.commit()
    conn.row_factory = sqlite3.Row
    return conn


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
    image_filename = f"{HISTORY_DIR}/{timestamp}_{button}.jpg"
    image.save(image_filename)

    response = False
    log_data = [timestamp, button, response, "-"]
    for person, access in KNOWN_PERSONS.items():
        person_folder = f"{KNOWN_FACES_DIR}/{person}"
        face_recognizer = DeepFace.verify(image_filename, person_folder)
        if face_recognizer["verified"] and access[int(button)] == "1":
            log_data[3] = person
            response = True
            break

    with get_connection() as conn:
        log_data = (timestamp, int(button), int(response), log_data[3])
        insert_attempt = '''
            INSERT INTO logs (timestamp, button, response, person)
            VALUES (?, ?, ?, ?)
        '''
        conn.execute(insert_attempt, log_data)
        conn.commit()

    return jsonify({'response': response}), 200


# API endpoint to retrieve image data based on name
@app.route('/image-data', methods=['GET'])
def get_image_data():
    image_filename = request.args.get('name')+".jpg"
    image_path = os.path.join(HISTORY_DIR, image_filename)

    if not os.path.isfile(image_path):
        return jsonify({'error': 'Image not found.'}), 404

    return send_file(image_path, mimetype='image/jpeg')


@app.route('/attempts', methods=['GET'])
def get_attempts():
    page = int(request.args.get('page', 1))
    per_page = int(request.args.get('per_page', 10))

    with get_connection() as conn:
        cursor = conn.cursor()
        query = "SELECT COUNT(*) FROM logs"
        cursor.execute(query)
        total_attempts = cursor.fetchone()[0]
        total_pages = (total_attempts - 1) // per_page + 1

        offset = (page - 1) * per_page
        query = "SELECT * FROM logs ORDER BY timestamp DESC LIMIT ? OFFSET ?"
        cursor.execute(query, (per_page, offset))
        rows = cursor.fetchall()

        attempts = []
        for row in rows:
            attempt = {
                'timestamp': row['timestamp'],
                'button': row['button'],
                'response': bool(row['response']),
                'person': row['person']
            }
            attempts.append(attempt)

    return jsonify({
        'attempts': attempts,
        'page': page,
        'has_previous_page' : page >1,
        'has_next_page' : page <total_pages,
        'total_pages': total_pages
    }), 200


if __name__ == '__main__':
    with open(ERROR_LOG, mode='a') as f:
        try:
            app.run(host='0.0.0.0', port=5000)
        except KeyboardInterrupt:
            print("Server stopped with CTRL+C")
        except Exception as e:
            f.write(datetime.now().strftime("%Y%m%d%H%M%S") + "  ")
            print_exc(file=f)
