import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import './notifiers/state.dart';
import './pages/login.dart';
import './pages/waiting.dart';
import './pages/info.dart';
import './utils/oauth.dart' show accessTokenFor, OAuthException;

void main() {
  // This has to be initialized before we can set the method call handler which
  // handles the callback URLs back from the native platform.
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (context) => AppState(),
      child: DecidimParticipantTokenApp()
    )
  );
}

// Allows accessing the context globally in order to show dialogs during
// events such as callback intents.
class NavigationService {
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
}

class DecidimParticipantTokenApp extends StatelessWidget {
  static const platform = const MethodChannel('fi.mainiotech.decidimparticipanttoken/native');

  DecidimParticipantTokenApp({Key? key}) : super(key: key) {
    platform.setMethodCallHandler(_handleNativeMessage);
  }

  // This widget is the root of the application.
  @override
  Widget build(BuildContext context) {
    TextStyle bodyTextStyle = Theme.of(context).textTheme.bodyMedium!.copyWith(
      fontSize: 16,
    );

    return MaterialApp(
      title: 'Decidim Participant Token',
      navigatorKey: NavigationService.navigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        textTheme: Theme.of(context).textTheme.copyWith(
          bodyMedium: bodyTextStyle
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF30BCFF),
            foregroundColor: Color(0xFFFFFFFF),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            textStyle: bodyTextStyle.copyWith(fontWeight: FontWeight.bold)
          )
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (BuildContext ctx) => const LoginPage(title: 'Login'),
        '/waiting': (BuildContext ctx) => const WaitingPage(title: 'Waiting'),
        '/info': (BuildContext ctx) => const InfoPage(title: 'Details from the API'),
      }
    );
  }

  Future<dynamic> _handleNativeMessage(MethodCall call) async {
    switch (call.method) {
      case 'callback':
        Uri uri = Uri.parse(call.arguments);
        _handleCallback(uri);
        return new Future.value(true);

      case 'activityResumedAfterWeb':
        Uri uri = Uri.parse(call.arguments);
        _handleWebActivityCancelled(uri);
        return new Future.value(true);
    }

    return new Future.value(false);
  }

  void _handleCallback(Uri uri) {
    if (uri.queryParameters['test'] == '1') {
      _showAlertDialog(
        'Configuration successful',
        'You have manually verified this application to handle the the development domain callback URL.'
      );
    } else if (uri.queryParameters['code'] != null) {
      _authenticateUser(uri);
    }
  }

  void _handleWebActivityCancelled(Uri uri) {
    String url = uri.toString().split('?').first;
    if (url == const String.fromEnvironment('OAUTH_AUTH_URL')) {
      BuildContext context = NavigationService.navigatorKey.currentContext!;
      Navigator.pushReplacementNamed(context, '/');

      _showAlertDialog(
        'Authentication cancelled',
        'The authentication process was cancelled. Please complete the authentication process in order to try the API.'
      );
    }
  }

  void _authenticateUser(Uri uri) async {
    BuildContext context = NavigationService.navigatorKey.currentContext!;
    AppState appState = Provider.of<AppState>(context, listen: false);

    try {
      appState.token = await accessTokenFor(uri, appState);

      Navigator.pushReplacementNamed(context, '/info');
    } on OAuthException catch (e) {
      _failAuthentication(e.message);
    }
  }

  void _failAuthentication(String message) {
    _showAlertDialog(
      'Authentication failed!',
      message
    );
  }

  Future<void> _showAlertDialog(String title, String text) async {
    BuildContext? context = NavigationService.navigatorKey.currentContext;
    if (context == null) {
      return;
    }

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(text),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

