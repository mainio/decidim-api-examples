import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../utils/string.dart' show multiline;
import '../utils/oauth.dart' show generateAuthUri;
import '../notifiers/state.dart';

class LoginPage extends StatefulWidget {
  final String title;

  const LoginPage({super.key, required this.title});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const platform = MethodChannel('fi.mainiotech.decidimparticipanttoken/native');

  @override
  Widget build(BuildContext context) {
    TextStyle titleStyle = Theme.of(context).textTheme.titleLarge!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF30BCFF),
        toolbarHeight: 0
      ),
      body: Align(
        alignment: Alignment.topLeft,
        child: Container(
          margin: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Example Decidim participant integration', style: Theme.of(context).textTheme.headlineLarge!),
              const SizedBox(height: 10),
              Text(
                multiline('''
                  This is a simple example application to demonstrate the participant sign in to the Decidim API. Please
                  read through the README documentation to prepare your Decidim instance for this integration.
                '''),
              ),
              const SizedBox(height: 20),
              Text('Important!', style: titleStyle),
              const SizedBox(height: 5),
              Text.rich(
                TextSpan(
                  children: <TextSpan>[
                    TextSpan(
                      text: 'This example is for demonstration purposes only and should only be used in development environment. ',
                      style: TextStyle(fontWeight: FontWeight.bold)
                    ),
                    TextSpan(
                      text: multiline('''
                        The way the integration is implemented requires the OAuth serving application (i.e. Decidim) to
                        be behind HTTPS secured connections. Without HTTPS, the integration is subject to
                        man-in-the-middle attacks and can cause serious security issues and user account hijacking.
                      '''),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text('Test the API', style: titleStyle),
              const SizedBox(height: 5),
              Text(
                multiline('''
                  Press the button below in order to start the authentication process with the configured Decidim instance.
                  You will be redirected to perform the authentication and token authorization at Decidim.
                ''')
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                child: ElevatedButton(
                  child: Text('Start the sign in process'),
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/waiting');

                    AppState state = Provider.of<AppState>(context, listen: false);
                    Uri uri = generateAuthUri(state);

                    platform.invokeMethod('launchUrl', uri.toString());
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
