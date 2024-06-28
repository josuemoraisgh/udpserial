import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:libserialport/libserialport.dart';

class UdpSerial {
  bool isConnected = false;
  SerialPort? _sp;
  SerialPortReader? _reader;
  final Completer<List<InternetAddress>> addressCompleter =
      Completer<List<InternetAddress>>();
  final Completer<RawDatagramSocket> configCompleter =
      Completer<RawDatagramSocket>();
  final String udpHost;
  final int udpPort;
  final String serialPort;
  final int baudRate;
  final int bytesize;
  final int parity;
  final int stopbits;
  UdpSerial({
    required this.udpHost,
    required this.udpPort,
    required this.serialPort,
    required this.baudRate,
    required this.bytesize,
    required this.parity,
    required this.stopbits,
  }) {
    _init();
  }
  Future<void> _init() async {
    if (!addressCompleter.isCompleted) {
      addressCompleter.complete(InternetAddress.lookup(udpHost));
    }
    if (!configCompleter.isCompleted) {
      configCompleter
          .complete(RawDatagramSocket.bind(InternetAddress.anyIPv4, udpPort));
    }
    final udpSocket = await configCompleter.future;
    print('UDP to serial connection tool');
    print('UDP:127.0.0.1:${udpSocket.port}');
    openSerial(serialPort,
        baudRate: baudRate,
        bytesize: bytesize,
        parity: parity,
        stopbits: stopbits);
    print(
        'Serial: port:$serialPort, baudRate:$baudRate, bytesize:$bytesize, parity:$parity, stopbits:$stopbits');
    final serverAddress = (await addressCompleter.future).first;
    await listen();
    udpSocket.send([255, 255, 0, 0, 255, 255, 0, 0], serverAddress, udpPort);
  }

  listen() async {
    final udpSocket = await configCompleter.future;
    udpSocket.listen((RawSocketEvent event) {
      if (event == RawSocketEvent.read) {
        Datagram? datagram = udpSocket.receive();
        if (datagram != null) {
          writeSerial(datagram.data);
        }
      }
    });
  }

  send(List<int> data) async {
    final udpSocket = await configCompleter.future;
    final serverAddress = (await addressCompleter.future).first;
    print(
        'UDP Send: ${data.map((e) => e.toRadixString(16).padLeft(2, '0')).join(" ").toUpperCase()} on ${serverAddress.address}');
    udpSocket.send(data, serverAddress, udpPort);
  }

  bool openSerial(String srialPort,
      {int? baudRate, int? bytesize, int? parity, int? stopbits}) {
    try {
      if (_sp != null) if (_sp!.isOpen) _sp!.close();
      _sp = SerialPort(serialPort);
      _reader = SerialPortReader(_sp!);
      if (_reader != null) {
        _reader!.stream.listen((Uint8List data) {
          if (data.isNotEmpty) {
            send(data.toList());
          }
        });
      }
      _sp!.openReadWrite();
      SerialPortConfig config = _sp!.config;
      //config.setFlowControl(SerialPortFlowControl.rtsCts);
      //config.cts = SerialPortCts.flowControl;
      //config.rts = SerialPortRts.flowControl;
      //config.xonXoff = SerialPortXonXoff.inOut;
      if (baudRate != null) {
        config.baudRate = baudRate;
      }
      if (bytesize != null) {
        config.bits = bytesize;
      }
      if (parity != null) {
        config.parity = parity;
      }
      if (stopbits != null) {
        config.stopBits = stopbits;
      }
      _sp!.config = config;
      return true;
    } on SerialPortError catch (err, _) {
      print(SerialPort.lastError);
    }
    return false;
  }

  bool writeSerial(Uint8List write) {
    int tam = 0;
    if (_sp != null) {
      if (_sp!.isOpen) {
        if (write.isNotEmpty) {
          try {
            if (write.length == 8 &&
                write[0] == 255 &&
                write[1] == 255 &&
                write[2] == 0 &&
                write[3] == 0 &&
                write[4] == 255 &&
                write[5] == 255 &&
                write[6] == 0 &&
                write[7] == 0) {
              isConnected = true;
              print('Connection OK');
            } else {
              tam = _sp!.write(write, timeout: 0);
            }
          } on SerialPortError catch (err, _) {
            print(SerialPort.lastError);
          }
        }
        if (tam >= write.length) {
          print(
              'UDP Recive: ${write.map((e) => e.toRadixString(16).padLeft(2, '0')).join(" ").toUpperCase()}');
          return true;
        }
      }
    }
    return false;
  }
}
