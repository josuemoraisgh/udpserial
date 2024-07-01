import 'dart:io';
import 'dart:async';

int countNumber = 8;
class CommUdp {
  RawDatagramSocket? udpSocket;
  InternetAddress? serverAddress;
  int? udpPort;

  Future<void> openUdp({
    required String udpHost,
    required int udpPort,
  }) async {
    this.udpPort = udpPort;
    for (int i = 0; i < countNumber; i++) {
      try {
        serverAddress = (await InternetAddress.lookup(udpHost)).first;
        udpSocket =
            await RawDatagramSocket.bind(InternetAddress.anyIPv4, udpPort);
        print('UDP Server: ${serverAddress!.address}:${udpSocket!.port}');
        udpSocket!
            .send([255, 255, 0, 0, 255, 255, 0, 0], serverAddress!, udpPort);
        i=countNumber;
      } on SocketException catch (err, _) {
        if (err.osError!.errorCode == 1101) {
          print("UDP ERROR: ${serverAddress!.address} desconeted!!");
        } else {
          print("UDP ERROR: ${err.message}");
        }
        if(i==countNumber-1) exit(0);
      }
    }
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
