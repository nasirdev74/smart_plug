import 'main.dart';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleConfigView extends StatefulWidget {
  const BleConfigView({super.key});

  @override
  State<BleConfigView> createState() => _BleConfigViewState();
}

class _BleConfigViewState extends State<BleConfigView> {
  var I = "";
  var E = "";
  var V = "";
  var led = false;
  var _log = "";
  var isConnecting = false;
  var isWriting = false;
  BluetoothDevice? device;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await configBle();
    });
  }

  log(String data) {
    developer.log(data);
    if (mounted) {
      setState(() {
        _log = data;
      });
    }
  }

  Future configBle() async {
    var isOn = await FlutterBluePlus.adapterState.first == BluetoothAdapterState.on;
    if (!isOn) {
      log("ble is not on: $isOn");
      log("requesting service...");
      await FlutterBluePlus.turnOn();
      configBle();
    }
    if (isOn) {
      log("ble turned on. start scanning...");
      await FlutterBluePlus.startScan(
        timeout: const Duration(minutes: 10),
        androidUsesFineLocation: true,
      );
      log("ble scanning started.");
    }
  }

  Future connectBle(BluetoothDevice device) async {
    try {
      await device.connect(timeout: CONNECT_TIMEOUT);
      log("connected -- (i)");
      await listenBle(device);
      await writeBle(device, credentialBleData);
    } catch (error) {
      log("failed to connect -- (i)");
      try {
        await device.connect(timeout: CONNECT_TIMEOUT);
        log("connected -- (ii)");
        await listenBle(device);
        await writeBle(device, credentialBleData);
      } catch (error) {
        log("failed to connect -- (ii)");
        try {
          await device.connect(timeout: CONNECT_TIMEOUT);
          log("connected -- (iii)");
          await listenBle(device);
          await writeBle(device, credentialBleData);
        } catch (error) {
          log("failed to connect -- (iii) -- giving up.");
        }
      }
    }
  }

  /// used to write data to bluetooth device
  Future writeBle(BluetoothDevice device, String data) async {
    try {
      var services = <BluetoothService>[];
      try {
        services = await device.discoverServices();
      } catch (e) {
        log("discover services failed.");
      }

      if (services.isNotEmpty) {
        for (var service in services) {
          if (service.uuid.toString() == "0180") {
            log("service uuid matched: ${service.uuid.toString()}");
            for (var characteristic in service.characteristics) {
              if (characteristic.uuid.toString() == "fefe") {
                log("notification characteristic matched: ${characteristic.uuid.toString()}");
                try {
                  log("writing data to ble: $data");
                  await characteristic.write(data.codeUnits);
                } catch (err) {
                  log("characteristic.setNotifyValue failed.");
                }
              }
            }
          }
        }
      }
    } catch (_) {}
  }

  Future listenBle(BluetoothDevice device) async {
    try {
      var services = <BluetoothService>[];
      try {
        services = await device.discoverServices();
      } catch (e) {
        log("discover services failed.");
      }

      if (services.isNotEmpty) {
        for (var service in services) {
          if (service.uuid.toString() == "0180") {
            log("service uuid matched: ${service.uuid.toString()}");
            for (var characteristic in service.characteristics) {
              if (characteristic.uuid.toString() == "fefe") {
                log("notification characteristic matched: ${characteristic.uuid.toString()}");
                try {
                  final result = await characteristic.setNotifyValue(true);
                  log("setNotifyValue: $result");

                  characteristic.lastValueStream.listen((e) {
                    final message = String.fromCharCodes(e).trim();
                    if (message.isNotEmpty) {
                      log("message received from BLE: $message");
                      if (mounted) {
                        setState(() {
                          if (message.startsWith("I")) I = message;
                          if (message.startsWith("E")) E = message;
                          if (message.startsWith("V")) V = message;
                          if (message.startsWith("LED_ON")) led = true;
                          if (message.startsWith("LED_OFF")) led = false;
                        });
                      }
                    }
                  });
                } catch (err) {
                  log("characteristic.setNotifyValue failed.");
                }
              }
            }
          }
        }
      }
    } catch (e) {
      log("listening for services failed: $e");
    }
  }

  final stylei = GoogleFonts.nunito(
    fontSize: 32,
    fontWeight: FontWeight.w600,
  );

  @override
  Widget build(BuildContext context) {
    final isAllEmpty = I.isEmpty && E.isEmpty && V.isEmpty;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          alignment: Alignment.bottomCenter,
          children: [
            Positioned(
              bottom: 25,
              child: Column(
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width - 30,
                    child: Text(
                      _log,
                      maxLines: 10,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.roboto(
                        fontSize: 15,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            !isAllEmpty
                ? Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Spacer(),
                      const Spacer(),
                      Text(I, style: stylei.copyWith(color: Colors.deepOrange)),
                      const Spacer(),
                      Text(E, style: stylei.copyWith(color: Colors.purpleAccent)),
                      const Spacer(),
                      Text(V, style: stylei.copyWith(color: Colors.pinkAccent)),
                      const Spacer(),
                      const Spacer(),
                    ],
                  )
                : StreamBuilder(
                    stream: FlutterBluePlus.scanResults,
                    initialData: const [],
                    builder: (_, result) {
                      developer.log(result.toString());
                      var devices = <ScanResult>[];
                      if (result.requireData.isNotEmpty) {
                        devices = (result.requireData as List<ScanResult>)
                            .where((e) => e.device.advName.startsWith("SLA_SP"))
                            .toList();
                      }

                      if (devices.isEmpty) {
                        return const Center(
                          child: SizedBox(
                            width: 100,
                            height: 100,
                            child: CircularProgressIndicator(
                              color: Colors.indigoAccent,
                              strokeWidth: 4,
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        itemCount: devices.length,
                        itemBuilder: (_, i) {
                          final device = devices.elementAt(i).device;
                          return SizedBox(
                            height: 85,
                            child: Material(
                              child: InkWell(
                                onTap: () async {
                                  if (!isConnecting) {
                                    isConnecting = true;
                                    this.device = device;
                                    await connectBle(device);
                                    isConnecting = false;
                                  }
                                },
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const SizedBox(width: 20),
                                    Text(
                                      device.advName,
                                      style: GoogleFonts.roboto(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 22,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
            Positioned(
              bottom: 65,
              child: CircleAvatar(
                radius: 30,
                backgroundColor: led ? Colors.red.shade700 : Colors.grey.shade400,
                child: IconButton(
                  icon: const Icon(
                    Icons.power_settings_new,
                    size: 30,
                  ),
                  color: Colors.white,
                  onPressed: () async {
                    if (!isWriting && device != null) {
                      isWriting = true;
                      await writeBle(device!, powerBleData);
                      isWriting = false;
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
