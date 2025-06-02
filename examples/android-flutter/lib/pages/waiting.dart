import 'package:flutter/material.dart';

class WaitingPage extends StatelessWidget {
  final String title;

  const WaitingPage({super.key, required this.title});

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
            children: const <Widget>[
              SizedBox(width: 60, height: 60, child: CircularProgressIndicator()),
              Padding(padding: EdgeInsets.only(top: 16), child: Text('Logging in...')),
            ]
          ),
        ),
      ),
    );
  }
}
