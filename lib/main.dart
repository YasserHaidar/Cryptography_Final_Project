import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:flutter/material.dart';
import 'package:rsa_encrypt/rsa_encrypt.dart';
import 'package:pointycastle/api.dart' as crypto;
import 'package:secure_chat/Alice.dart';
import 'package:secure_chat/des_manager.dart';
import 'package:firebase_database/firebase_database.dart';
import 'Bob.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Secure Chat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(
        title: 'Secure Chat',
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  switchtoAlice() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) {
              return Alice();
            },
            maintainState: false));
  }

  switchtoBob() {
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) {
              return Bob();
            },
            maintainState: false));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      /*  appBar: AppBar(
          centerTitle: true,
          title: Text(
            widget.title,
          ),
        ),*/
        body: Column(
          // mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image.asset("assets/end_2_end.jpeg",width: 100,height: 100,),
            Text(
              "First,Choose an Identity ",
              style: TextStyle(
                fontSize: 15,
                color: Colors.black,
              ),
            ),
            Divider(
              height: 40,
            ),
            Center(
              child: Container(
                color: Colors.blue,
                child: FlatButton(
                    //This button retrieves the value of the second user DES key
                    onPressed: switchtoAlice,
                    color: Colors.blue,
                    child: Text(
                      "Alice",
                      style: TextStyle(color: Colors.white),
                    )),
              ),
            ),
            Divider(
              height: 40,
            ),
            Center(
              child: Container(
                color: Colors.blue,
                child: FlatButton(
                    //This button retrieves the value of the second user DES key
                    onPressed: switchtoBob,
                    color: Colors.blue,
                    child: Text(
                      "Bob",
                      style: TextStyle(color: Colors.white),
                    )),
              ),
            ),
            Divider(
              height: 40,
            ),
            Icon(Icons.warning_rounded,color: Colors.yellow,),
            Center(
              child: Text(
                "This Application provides an End-To-End Encryption for the conservation done between Alice and Bob.It is based on RSA and Triple DES with OFB mode",
                style: TextStyle(color: Colors.redAccent, fontSize: 14,),
                textAlign: TextAlign.center,
              ),
            ),

          ],
        )
        // This trailing comma makes auto-formatting nicer for build methods.
        );
  }
}
