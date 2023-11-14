import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:plug/ble_config.dart';

final credentialBleData = json.encode({
  "ssid": "sm_deco",
  "pass": "sales152152",
  "uuid": "71086a4a-68d3-11ee-8c99-0242ac120002",
  "topic": "832c4ee4-68d3-11ee-8c99-0242ac120002"
});

final powerBleData = json.encode({"pwr": 1});

const BLUETOOTH_SERVICE_UUID = "37fc19ab-98ca-4543-a68b-d183da78acdc";
const BLUETOOTH_WRITE_UUID = "a40d0c2e-73ba-4d8b-8eef-9a0666992e56";
const BLUETOOTH_NOTIFICATION_UUID = "49535343-8841-43f4-a8d4-ecbe34729bb3";
const CONNECT_TIMEOUT = Duration(seconds: 3);

main() => runApp(const SmartPlugApp());

class SmartPlugApp extends StatelessWidget {
  const SmartPlugApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: BleConfigView(),
    );
  }
}
