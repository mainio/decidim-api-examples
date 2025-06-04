import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../utils/string.dart' show multiline;
import '../utils/api.dart' show apiRequest;
import '../notifiers/state.dart';

class InfoPage extends StatefulWidget {
  final String title;

  const InfoPage({super.key, required this.title});

  @override
  State<InfoPage> createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage> {
  static const platform = MethodChannel('fi.mainiotech.decidimparticipanttoken/native');

  @override
  Widget build(BuildContext context) {
    TextStyle linkStyle = Theme.of(context).textTheme.bodyMedium!.copyWith(
      color: Colors.blue,
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF30BCFF),
        toolbarHeight: 0
      ),
      body: Align(
        alignment: Alignment.topLeft,
        child: Container(
          margin: EdgeInsets.all(20),
          child: FutureBuilder<Map<String, dynamic>>(
            future: _fetchData(),
            builder: (BuildContext context, AsyncSnapshot<Map<String, dynamic>> snapshot) {
              final restartButton = Container(
                width: double.infinity,
                child: ElevatedButton(
                  child: Text('Restart'),
                  onPressed: _restartApp,
                ),
              );

              List<Widget> children;
              if (snapshot.hasData && snapshot.data != null) {
                Map<String, dynamic> user = snapshot.data!['user'];
                Map<String, dynamic> token = snapshot.data!['token'];

                DateTime createdAt = DateTime.fromMillisecondsSinceEpoch(
                  (token['created_at'] as int) * 1000
                );
                DateTime expiresAt = DateTime.fromMillisecondsSinceEpoch(
                  createdAt.millisecondsSinceEpoch + (token['expires_in'] as int) * 1000
                );

                children = <Widget>[
                  Text('You are now signed in at Decidim', style: Theme.of(context).textTheme.headlineLarge!),
                  const SizedBox(height: 10),
                  const Text('Your user details at Decidim are listed below:'),
                  const SizedBox(height: 5),
                  DetailsList(<String, Widget>{
                    'Name': Text(user['name']),
                    'Nickname': RichText(
                      text: TextSpan(
                        text: user['nickname'],
                        style: linkStyle,
                        recognizer: TapGestureRecognizer()
                          ..onTap = () =>{
                            _openProfile(user['profilePath'] as String),
                          }
                      ),
                    ),
                  }),
                  const SizedBox(height: 20),
                  const Text('Your token details:'),
                  const SizedBox(height: 5),
                  DetailsList(<String, Widget>{
                    'Created at': Text(createdAt.toString()),
                    'Expires at': Text(expiresAt.toString())
                  }),
                  const SizedBox(height: 20),
                  const Text('Capabilities associated with the token:'),
                  const SizedBox(height: 5),
                  BulletList(_tokenCapabilities(token['scope'])),
                  const Divider(height: 60, thickness: 1, color: Colors.black),
                  restartButton,
                ];
              } else if (snapshot.hasError) {
                children = <Widget>[
                  Text('Error fetching the data', style: Theme.of(context).textTheme.headlineLarge!),
                  const SizedBox(height: 10),
                  const Text('Either the API token is expired or there is a configuration error with Decidim.'),
                  const SizedBox(height: 10),
                  Text('Error: ${snapshot.error}'),
                ];
              } else {
                children = const <Widget>[
                  SizedBox(width: 60, height: 60, child: CircularProgressIndicator()),
                  Padding(padding: EdgeInsets.only(top: 16), child: Text('Loading details...')),
                ];
              }

              return Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children
              );
            }
          ),
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> _fetchData() async {
    AppState appState = Provider.of<AppState>(context, listen: false);
    String query = '{ session { user { id name nickname profilePath } } }';
    final data = await apiRequest(appState.token!, query);

    return {
      'user': data['session']!['user'],
      'token': appState.token
    };
  }

  List<String> _tokenCapabilities(String tokenScopes) {
    List<String> scopes = tokenScopes.split(' ');
    List<String> capabilities = [];

    if (scopes.contains('profile')) {
      capabilities.add('Can read profile information about the user.');
    }
    if (scopes.contains('user')) {
      capabilities.add('Can represent the user through the API.');
    }
    if (scopes.contains('api:read')) {
      capabilities.add('Can read data through the API.');
    }
    if (scopes.contains('api:write')) {
      capabilities.add('Can write data through the API.');
    }

    return capabilities;
  }

  void _openProfile(String profilePath) {
    Uri uri = Uri.parse(const String.fromEnvironment('API_URL')).replace(
      path: profilePath
    );

    platform.invokeMethod('launchUrl', uri.toString());
  }

  void _restartApp() {
    AppState appState = Provider.of<AppState>(context, listen: false);
    appState.token = null;
    Navigator.pushReplacementNamed(context, '/');
  }
}

class DetailsList extends StatelessWidget {
  final Map<String, Widget> details;

  DetailsList(this.details);

  @override
  Widget build(BuildContext context) {
    return Table(
      defaultVerticalAlignment: TableCellVerticalAlignment.top,
      columnWidths: const <int, TableColumnWidth>{
        0: IntrinsicColumnWidth(),
        1: FixedColumnWidth(15),
        2: FlexColumnWidth(),
      },
      children: <TableRow>[
        ...this.details.entries.map((entry) {
          return TableRow(
            children: <Widget>[
              Text('${entry.key}:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(''),
              entry.value,
            ],
          );
        }).toList()
      ]
    );
  }
}

class BulletList extends StatelessWidget {
  final List<String> items;

  BulletList(this.items);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ...this.items.map((item) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(
                  left: 15,
                  top: 8,
                  right: 5,
                  bottom: 8,
                ),
                height: 5.0,
                width: 5.0,
                decoration: BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 5),
              Expanded(child: Text(item))
            ],
          );
        })
      ]
    );
  }
}
