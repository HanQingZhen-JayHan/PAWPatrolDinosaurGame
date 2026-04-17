import 'dart:io';

class NetworkUtils {
  NetworkUtils._();

  /// Finds the first non-loopback IPv4 address on the local machine.
  static Future<String?> getLocalIpAddress() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback) {
            return addr.address;
          }
        }
      }
    } catch (_) {}
    return null;
  }

  /// Finds an available port starting from [startPort].
  static Future<int> findAvailablePort({int startPort = 8080}) async {
    for (var port = startPort; port < startPort + 100; port++) {
      try {
        final server = await ServerSocket.bind(
          InternetAddress.anyIPv4,
          port,
        );
        await server.close();
        return port;
      } catch (_) {
        continue;
      }
    }
    throw StateError('No available port found in range $startPort-${startPort + 99}');
  }

  /// Builds the WebSocket URL for controllers to connect to.
  static String buildWsUrl(String ip, int port) => 'ws://$ip:$port/ws';
}
