from flask import Flask, request
import json
import firebase_admin
from firebase_admin import credentials, messaging

cred = credentials.Certificate("safespace_backend/certificate.json")
firebase_admin = firebase_admin.initialize_app(cred)


app = Flask(__name__)
currentTokens = []
crime_location_history = []
@app.route("/")
def default():
  return "App is Up"

@app.route('/subscribe', methods=['POST'])
def subscribe():
    dict = json.loads(request.data.decode('utf-8'))
    print(dict["token"])
    if dict["token"] not in currentTokens:
        currentTokens.append(dict["token"])
    print(currentTokens)
    return " "

@app.route('/send_crime_location_history', methods=['GET'])
def send_crime_location_history():
    print(crime_location_history)
    crime_location_dict = {"crime location history": crime_location_history}
    
    return crime_location_dict

@app.route('/receive_signal', methods=['POST'])
def receive_signal(): #comes in as json
    received_json = json.loads(request.data.decode('utf-8'))
    received_token = received_json["sender_token"]
    
    current_tokens_copy = currentTokens[:]
    del current_tokens_copy[currentTokens.index(received_token)]

    crime_location = [float(received_json["data"]["lat"]), float((received_json["data"]["long"]))]
    if crime_location not in crime_location_history:
        crime_location_history.append(crime_location)

    message = messaging.MulticastMessage(
        notification=messaging.Notification(
            title=received_json["notification"]["title"],
            body=received_json["notification"]["body"]
        ),
        android=messaging.AndroidConfig(
            priority="normal",
            notification=messaging.AndroidNotification(
                color="#8E0000"
            )
        ),
        data={
            "lat": received_json["data"]["lat"],
            "long": received_json["data"]["long"]
        },
        tokens=current_tokens_copy
    )
    response = messaging.send_multicast(message)
    print(response)
    return " "
    
if __name__ == "__main__":
    app.run()