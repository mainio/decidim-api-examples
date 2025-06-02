import 'dart:math';
import 'dart:convert';
import 'package:crypto/crypto.dart';

String multiline(String str) {
  return str.replaceAll(RegExp(r'\n(\s{2,})+'), ' ').trim();
}

String randomString(List<String> chars, int len) {
  var r = Random.secure();

  return List<String>.generate(len, (_) => chars[r.nextInt(chars.length)]).join();
}

Digest digestMessage(String message) {
  var bytes = utf8.encode(message);
  return sha256.convert(bytes);
}

String base64urlencode(List<int> bytes) {
  // Generates an unpadded base64 encoded URL string, see:
  // https://datatracker.ietf.org/doc/html/rfc7636#appendix-A
  String encoded = base64.encode(bytes);
  return encoded.split('=')[0].replaceAll('+', '-').replaceAll('/', '_');
}
