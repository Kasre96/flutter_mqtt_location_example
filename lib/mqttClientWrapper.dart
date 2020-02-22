import 'package:flutter/material.dart';
import 'package:flutter_mqtt_location_example/converter.dart';
import 'package:flutter_mqtt_location_example/constants.dart' as Constants;
import 'package:location/location.dart';
import 'package:mqtt_client/mqtt_client.dart';

import 'models.dart';

class MQTTClientWrapper {
  // mqtt client instance
  MqttClient client;

  LocationToJsonConverter locationToJsonConverter = LocationToJsonConverter();
  JsonToLocationConverter jsonToLocationConverter = JsonToLocationConverter();

  // set default sub and conn states
  MqttCurrentConnectionState connectionState = MqttCurrentConnectionState.IDLE;
  MqttSubscriptionState subscriptionState = MqttSubscriptionState.IDLE;

  final VoidCallback onConnectedCallback;
  final Function(LocationData) onLocationReceivedCallback;

  // constructor
  MQTTClientWrapper(this.onConnectedCallback, this.onLocationReceivedCallback);

  
  void prepareMqttClient() async {
    _setupMqttClient();
    await _connectClient();
    _subscribeToTopic(Constants.topicName);
  }

  /// converts passed location to json ready for publishing
  void publishLocation(LocationData locationData) {
    String locationJson = locationToJsonConverter.convert(locationData);
    _publishMessage(locationJson);
  }

// method to establish connection to mqtt server
  Future<void> _connectClient() async {
    try {
      // set connection state to connecting
      print('MQTTClientWrapper::Mosquitto client connecting....');
      connectionState = MqttCurrentConnectionState.CONNECTING;

      // establish the connection
      await client.connect();
    } on Exception catch (e) {
      // set connection state to err while connecting
      print('MQTTClientWrapper::client exception - $e');
      connectionState = MqttCurrentConnectionState.ERROR_WHEN_CONNECTING;

      // disconnect from client instance
      client.disconnect();
    }

    // check the connection state
    if (client.connectionStatus.state == MqttConnectionState.connected) {
      // set connection state to connected
      connectionState = MqttCurrentConnectionState.CONNECTED;
      print('MQTTClientWrapper::Mosquitto client connected');
    } else {
      print(
          'MQTTClientWrapper::ERROR Mosquitto client connection failed - disconnecting, status is ${client.connectionStatus}');

      // set connection state to err while connecting and disconnect from instance
      connectionState = MqttCurrentConnectionState.ERROR_WHEN_CONNECTING;
      client.disconnect();
    }
  }

  /// sets up mqtt client and connection params
  void _setupMqttClient() {
    client = MqttClient.withPort(Constants.serverUri, '#', Constants.port);
    client.logging(on: false);
    client.keepAlivePeriod = 20;
    client.onDisconnected = _onDisconnected;
    client.onConnected = _onConnected;
    client.onSubscribed = _onSubscribed;
  }

  void _subscribeToTopic(String topicName) {
    print('MQTTClientWrapper::Subscribing to the $topicName topic');
    // subscribe
    client.subscribe(topicName, MqttQos.atMostOnce);

  // listen
    client.updates.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final MqttPublishMessage recMess = c[0].payload;
      final String newLocationJson =
          MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

      print("MQTTClientWrapper::GOT A NEW MESSAGE $newLocationJson");
      LocationData newLocationData = _convertJsonToLocation(newLocationJson);
      if (newLocationData != null) onLocationReceivedCallback(newLocationData);
    });
  }

  LocationData _convertJsonToLocation(String newLocationJson) {
    try {
      return jsonToLocationConverter.convert(newLocationJson);
    } catch (exception) {
      print("Json can't be formatted ${exception.toString()}");
    }
    return null;
  }

  /// Published new location to mqtt
  void _publishMessage(String message) {
    final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
    builder.addString(message);

    print(
        'MQTTClientWrapper::Publishing message $message to topic ${Constants.topicName}');
    client.publishMessage(
        Constants.topicName, MqttQos.exactlyOnce, builder.payload);
  }

  /// called when client subscribes to topic
  void _onSubscribed(String topic) {
    print('MQTTClientWrapper::Subscription confirmed for topic $topic');
    subscriptionState = MqttSubscriptionState.SUBSCRIBED;
  }

  /// called when mqtt server disconnects.
  void _onDisconnected() {
    print(
        'MQTTClientWrapper::OnDisconnected client callback - Client disconnection');
    if (client.connectionStatus.returnCode == MqttConnectReturnCode.solicited) {
      print(
          'MQTTClientWrapper::OnDisconnected callback is solicited, this is correct');
    }
    connectionState = MqttCurrentConnectionState.DISCONNECTED;
  }

  /// called when mqtt server is connected
  void _onConnected() {
    connectionState = MqttCurrentConnectionState.CONNECTED;
    print(
        'MQTTClientWrapper::OnConnected client callback - Client connection was sucessful');
    onConnectedCallback();
  }
}
