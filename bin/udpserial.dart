import 'package:udpserial/udpserial.dart';

void main(List<String> arguments) async {
  final int tam = arguments.length;
  UdpSerial(
    udpHost: tam > 0 ? arguments[0] : "inindkit0",
    udpPort: tam > 1 ? int.parse(arguments[1]): 4000,
    serialPort: tam > 2 ? arguments[2] : "CNCA0",
    baudRate: tam > 3 ? int.parse(arguments[3]):  1200,
    bytesize: tam > 4 ? int.parse(arguments[4]) : 8,
    parity: tam > 5 ? int.parse(arguments[5]) : 1,
    stopbits: tam > 6 ? int.parse(arguments[6]) : 1,
  );
}
