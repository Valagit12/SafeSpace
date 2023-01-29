from flask import Flask, request
import json
import firebase_admin
from firebase_admin import credentials, messaging
from ast import literal_eval

cred = credentials.Certificate("safespace_backend/certificate.json")
firebase_admin = firebase_admin.initialize_app(cred)


app = Flask(__name__)
@app.route("/")
def default():
  return "App is Up"

@app.route('/subscribe', methods=['POST'])
def subscribe():
    dict = json.loads(request.data.decode('utf-8'))

    text_list = []
    with open('safespace_backend/tokens.txt', 'r+') as file:
        for line in file:
            text_list.append(line.rstrip())
        # print(text_list)
        if dict["token"] not in text_list:
            file.write(dict["token"])
            file.write("\n")

    print(text_list)
    return " "

@app.route('/send_crime_location_history', methods=['GET'])
def send_crime_location_history():
    crime_location_history = []
    with open('safespace_backend/crime_location_history.txt', 'r') as file:
        for line in file:
            crime_location_history.append(literal_eval(line.rstrip()))
    print(crime_location_history)
    crime_location_dict = {"crime location history": crime_location_history}
    return crime_location_dict

@app.route('/receive_signal', methods=['POST'])
def receive_signal(): #comes in as json
    received_json = json.loads(request.data.decode('utf-8'))
    received_token = received_json["sender_token"]
    
    token_list = []
    with open('safespace_backend/tokens.txt', 'r') as file:
        for line in file:
            token_list.append(line.rstrip())

    current_tokens_copy = token_list[:]
    del current_tokens_copy[token_list.index(received_token)]

    crime_location_history = []
    with open('safespace_backend/crime_location_history.txt', 'r+') as file:
        for line in file:
            crime_location_history.append(line.rstrip())
        crime_location = [float(received_json["data"]["lat"]), float((received_json["data"]["long"]))]
        print(crime_location_history)
        if str(crime_location) not in crime_location_history:
            file.write(str(crime_location))
            file.write("\n")
            # crime_location_history.append(crime_location)


    

    # crime_location = [float(received_json["data"]["lat"]), float((received_json["data"]["long"]))]
    # if crime_location not in crime_location_history:
    #     crime_location_history.append(crime_location)

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