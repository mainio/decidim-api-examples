import 'dart:convert';
import 'package:http/http.dart' as http;
import '../notifiers/state.dart';
import './string.dart' show randomString, digestMessage, base64urlencode;

class OAuthException implements Exception {
  final String message;

  OAuthException(this.message);
}

String createOauthState() {
  // https://datatracker.ietf.org/doc/html/rfc6749#appendix-A.5
  List<String> chars = List<String>.generate(1 + 0x7E - 0x20, (idx) => String.fromCharCode(0x20 + idx));

  // According to RFC 6749, there is no specified maximum limit for the state
  // string, so we use a 36 character string which produces a 48 character
  // string when base64 encoded. This should give enough uniqueness among the
  // different authentication requests, as this is only used to verify the
  // authorization response is originating from the same user session.
  return randomString(chars, 36);
}

String createOauthVerifier() {
  // https://datatracker.ietf.org/doc/html/rfc7636#section-4.1
  const List<List<int>> ranges = [
    [0x30, 0x39], // 0-9
    [0x41, 0x5A], // A-Z
    [0x61, 0x7A] // a-z
  ];

  final chars = <String>[];
  for (List<int> range in ranges) {
    chars.addAll(List<String>.generate(1 + range[1] - range[0], (idx) => String.fromCharCode(range[0] + idx)));
  }

  // Extra characters
  chars.addAll(["-", ".", "_", "~"]);

  // According to RFC 7636, the verifier length needs to be between 43-128
  // characters which equates to 32-96 characters when Base64 encoded.
  return randomString(chars, 96);
}

Uri generateAuthUri(AppState state) {
  Uri uri = Uri.parse(const String.fromEnvironment('OAUTH_AUTH_URL'));
  Uri redirectUri = uri.replace(path: '/oauth/authorize/native');
  const String clientId = const String.fromEnvironment('OAUTH_CLIENT_ID');

  String oauthState = base64urlencode(utf8.encode(createOauthState()));
  String oauthVerifier = createOauthVerifier();
  String challenge = base64urlencode(digestMessage(oauthVerifier).bytes);

  state.oauthVerifier = oauthVerifier;
  state.oauthState = oauthState;

  return uri.replace(
    queryParameters: {
      'response_type': 'code',
      'client_id': clientId,
      'redirect_uri': redirectUri.toString(),
      'scope': 'profile user api:read',
      'state': oauthState,
      'code_challenge': challenge,
      'code_challenge_method': 'S256'
    }
  );
}

Future<Map<String, dynamic>> accessTokenFor(Uri uri, AppState appState) async {
  String? storedState = appState.oauthState;
  String? storedVerifier = appState.oauthVerifier;
  appState.oauthState = null;
  appState.oauthVerifier = null;
  if (storedState == null || storedVerifier == null) {
    throw OAuthException('OAuth state is unknown.');
  }

  String? code = uri.queryParameters['code'];
  String? state = uri.queryParameters['state'];
  if (code == null || code!.length < 1) {
    throw OAuthException('Authentication code was not returned for the callback.');
  }
  if (state == null || state!.length < 1) {
    throw OAuthException('Authentication state was not returned for the callback.');
  }
  if (storedState != state) {
    throw OAuthException('The authentication state does not match the stored state.');
  }

  Uri tokenUri = Uri.parse(const String.fromEnvironment('OAUTH_TOKEN_URL'));
  Uri redirectUri = tokenUri.replace(path: '/oauth/authorize/native');
  const String clientId = const String.fromEnvironment('OAUTH_CLIENT_ID');

  Map<String, String> params = {
    'grant_type': 'authorization_code',
    'code': code,
    'redirect_uri': redirectUri.toString(),
    'client_id': clientId,
    'code_verifier': storedVerifier,
  };

  http.Response response = await http.post(tokenUri, body: params);

  if (response.statusCode != 200) {
    throw OAuthException('Invalid response from the token endpoint.');
  }

  return json.decode(response.body);
}
