import 'dart:io';
import 'dart:typed_data';

import 'package:udpserial/comm_udp.dart';
import 'package:udpserial/comm_serial.dart';

bool isConnected = false;
final serial = CommSerial();
final udp = CommUdp();

void funcUdp(Datagram? datagram) {
  if (datagram != null) {
    if (datagram.data.length == 8 &&
        datagram.data[0] == 255 &&
        datagram.data[1] == 255 &&
        datagram.data[2] == 0 &&
        datagram.data[3] == 0 &&
        datagram.data[4] == 255 &&
        datagram.data[5] == 255 &&
        datagram.data[6] == 0 &&
        datagram.data[7] == 0) {
      isConnected = true;
      print('Connection OK');
    } else {
      print(
          'UDP Recive: ${datagram.data.map((e) => e.toRadixString(16).padLeft(2, '0')).join(" ").toUpperCase()}');
      serial.writeSerial(datagram.data);
    }
  }
}

void funcSerial(Uint8List data) {
  udp.send(data.toList());
}

Future<void> main(List<String> arguments) async {
  final int tam = arguments.length;
  print('UDP to serial connection tool');
  serial.openSerial(
    serialPort: tam > 2 ? arguments[2] : "CNCA0",
    baudRate: tam > 3 ? int.parse(arguments[3]) : 1200,
    bytesize: tam > 4 ? int.parse(arguments[4]) : 8,
    parity: tam > 5 ? int.parse(arguments[5]) : 1,
    stopbits: tam > 6 ? int.parse(arguments[6]) : 1,
  );
  await udp.openUdp(
    udpHost: tam > 0 ? arguments[0] : "10.0.64.28",
    udpPort: tam > 1 ? int.parse(arguments[1]) : 4000,
  );
  
  serial.listenReader(funcSerial);
  udp.listenReader(funcUdp);
}
