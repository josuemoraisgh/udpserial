import 'dart:io';
import 'dart:async';

class CommUdp {
  RawDatagramSocket? udpSocket;
  InternetAddress? serverAddress;
  int? udpPort;

  Future<void> openUdp({
    required String udpHost,
    required int udpPort,
  }) async {
    this.udpPort = udpPort;
    serverAddress = (await InternetAddress.lookup(udpHost)).first;
    udpSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, udpPort);
    print('UDP Server: ${serverAddress!.address}:${udpSocket!.port}');
    udpSocket!.send([255, 255, 0, 0, 255, 255, 0, 0], serverAddress!, udpPort);
  }

  void listenReader(void Function(Datagram? datagram) dataFunc) async {
    if (udpSocket != null) {
      udpSocket!.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          dataFunc(udpSocket!.receive());
        }
      });
    }
  }

  send(List<int> data) async {
    if (udpPort != null && udpSocket != null && serverAddress != null) {
      print(
          'UDP Send: ${data.map((e) => e.toRadixString(16).padLeft(2, '0')).join(" ").toUpperCase()} on ${serverAddress!.address}');
      udpSocket!.send(data, serverAddress!, udpPort!);
    }
  }
}
