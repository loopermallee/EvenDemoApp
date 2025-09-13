  // === Compatibility shims (allow older code to compile) ===

  // Old proto.dart used this; now just reflect the single "isConnected" flag.
  bool isBothConnected() => isConnected;

  // Old "request" API: we now just forward to sendData and pretend success.
  Future<Map<String, dynamic>> request(Uint8List data, {String? lr}) async {
    await sendData(data, lr: lr);
    return {"ok": true, "data": Uint8List(0)};
  }

  // Old "requestList" API: sequentially send and report success.
  Future<bool> requestList(List<Uint8List> list, {String? lr}) async {
    for (final d in list) {
      await sendData(d, lr: lr);
    }
    return true;
  }