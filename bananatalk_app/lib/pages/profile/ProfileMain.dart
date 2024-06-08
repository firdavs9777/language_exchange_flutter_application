import 'package:bananatalk_app/pages/authentication/screens/login.dart';
import 'package:flutter/material.dart';

class ProfileMain extends StatelessWidget {
  const ProfileMain({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        actions: <Widget>[
          IconButton(
              onPressed: () {
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (ctx) => Login()));
              },
              icon: Icon(Icons.logout))
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            child: Image.asset('assets/images/rome.png'),
            width: double.infinity,
            color: Colors.amber,
          ),
          SizedBox(height: 10.0),
          Text(
            'Firdavs Mutalipov',
            style: TextStyle(
              fontSize: 22.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10.0),
          Text(
            'Seoul, 27',
            style: TextStyle(
              fontSize: 18.0,
              color: Colors.grey,
            ),
          ),
          Card(
            child: ListTile(
              trailing: Icon(Icons.keyboard_arrow_right),
              title: Text('Event'),
            ),
          ),
          Card(
            child: ListTile(
              trailing: Icon(Icons.keyboard_arrow_right),
              title: Text('Notice'),
            ),
          ),
          Card(
            child: ListTile(
              trailing: Icon(Icons.keyboard_arrow_right),
              title: Text('Settings'),
            ),
          ),
        ],
      ),
    );
  }
}
