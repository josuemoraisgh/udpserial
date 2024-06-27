import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:libserialport/libserialport.dart';

class UdpSerial {
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
      final serverAddress = (await addressCompleter.future).first;    
      configCompleter.complete(RawDatagramSocket.bind(serverAddress.address, udpPort));
    }
    openSerial(serialPort,
        baudRate: baudRate,
        bytesize: bytesize,
        parity: parity,
        stopbits: stopbits);
  }

  listen(final void Function(String message) readMensagem) async {
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

  send(Uint8List data) async {
    final udpSocket = await configCompleter.future;
    final serverAddress = (await addressCompleter.future).first;    
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
          send(data);
        });
      }
      _sp!.openReadWrite();
      SerialPortConfig config = _sp!.config;
      config.setFlowControl(SerialPortFlowControl.rtsCts);
      config.cts = SerialPortCts.flowControl;
      config.rts = SerialPortRts.flowControl;
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
            tam = _sp!.write(write, timeout: 0);
          } on SerialPortError catch (err, _) {
            print(SerialPort.lastError);
          }
        }
        if (tam >= write.length) return true;
      }
    }
    return false;
  }
}
