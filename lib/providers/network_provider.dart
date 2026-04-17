import 'package:flutter/foundation.dart';

enum ConnectionStatus { disconnected, connecting, connected, error }

class NetworkProvider extends ChangeNotifier {
  ConnectionStatus _status = ConnectionStatus.disconnected;
  String _errorMessage = '';

  ConnectionStatus get status => _status;
  String get errorMessage => _errorMessage;
  bool get isConnected => _status == ConnectionStatus.connected;

  void setStatus(ConnectionStatus status, {String error = ''}) {
    _status = status;
    _errorMessage = error;
    notifyListeners();
  }
}
