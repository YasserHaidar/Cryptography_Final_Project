import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:flutter/material.dart';
import 'package:rsa_encrypt/rsa_encrypt.dart';
import 'package:pointycastle/api.dart' as crypto;
import 'package:secure_chat/des_manager.dart';
import 'dart:math';
import 'Alice.dart';

class Bob extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

TripleDes d;
String Bob_DES_key = "968314835893053678736231"; // default key for Bob in case Random secure didn't work
final databaseReference = FirebaseDatabase.instance.reference();

class _MyHomePageState extends State<Bob> {
  TextEditingController usermessage;
  DatabaseReference AlicePubKeys;
  DatabaseReference AliceDESKeys;
  String pub = "Not Generated Yet";
  String private = "Not Generated Yet";
  String Alice_Pub = "";
  // String Alice_Encrypted_Des = "";
  String Recieved_Alice_DES_Key = "";
  bool _loadPublic = false;
  bool _hideDetails = true;
  String _Encrypted_Bob_DES = "";

  @override
  void initState() {
    usermessage = TextEditingController();
    Bob_DES_key = CreateCryptoRandomString().substring(0,24);
    setState(() {
      getKey();
    });

    AlicePubKeys = databaseReference.child('Alice_Pub_Keys');
    AlicePubKeys.onChildAdded.listen(_onAliceKeyAdded);
    AlicePubKeys.onChildChanged.listen(_onAliceKeyAdded);
    AliceDESKeys = databaseReference.child('Alice_DES_Keys');
    AliceDESKeys.onChildAdded.listen(_onAliceDESAdded);
    AliceDESKeys.onChildChanged.listen(_onAliceDESAdded);
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }
  static final Random _random = Random.secure();

  String CreateCryptoRandomString([int length = 16]) {
    var values = List<int>.generate(length, (i) => _random.nextInt(256));
    print(base64Url.encode(values));

    return base64Url.encode(values);
  }
  ///RSA =>
  Future<crypto.AsymmetricKeyPair> futureKeyPair;
  //to store the KeyPair once we get data from our future
  crypto.AsymmetricKeyPair keyPair;
  Future<crypto.AsymmetricKeyPair<crypto.PublicKey, crypto.PrivateKey>>
      getKeyPair() {
    var helper = RsaKeyHelper();
    return helper.computeRSAKeyPair(helper.getSecureRandom());
  }

  getKey() async {
    futureKeyPair = getKeyPair();
    keyPair = await futureKeyPair;
    var helper = RsaKeyHelper();
    pub = helper.encodePublicKeyToPemPKCS1(keyPair.publicKey);
    private = helper.encodePrivateKeyToPemPKCS1(keyPair.privateKey);
    setState(() {
      _loadPublic = true;
    });
    sendPubKey();
  }

  ///Real Time Database:

  _onAliceKeyAdded(Event event) {
    print(event.snapshot.value);
    setState(() {
      Alice_Pub = event.snapshot.value;
      print("Alice Public Key Received");
    });
    sendBobDESKey();
  }

  _onAliceDESAdded(Event event) {
    print("DES_Alice Changed " + event.snapshot.value);
    setState(() {
      Recieved_Alice_DES_Key = event.snapshot.value;
    });
    _decryptSenderDESKey();
  }

  sendPubKey() {
    //channel.sink.add("Alice Pub Key" + pub.substring(0, 40));
    if (pub != "") {
      databaseReference.child("Bob_Pub_Keys").set({'Pub_Key': pub});
    } else {
      print("Public key not retrieved yet!");
    }
  }

  sendBobDESKey() {
    print("We are now encrypting Bob DES key");
    var helper = RsaKeyHelper();
    String msg = encrypt(
        Bob_DES_key,
        helper.parsePublicKeyFromPem(
            Alice_Pub)); //if we want to sign we use the private one instead and at decryption we use public
    //print(msg);
    setState(() {
      _Encrypted_Bob_DES = msg;
    });
    databaseReference.child("Bob_DES_Keys").set({"DES_Key": msg});
  }

  String Alice_Decrypted_DES = "";
  _decryptSenderDESKey() {
    //print("Before Decryption: "+ Recieved_Alice_DES_Key);
    if (Recieved_Alice_DES_Key != "" && private != "") {
      var helper = RsaKeyHelper();
      String _msg = decrypt(
          Recieved_Alice_DES_Key,
          helper.parsePrivateKeyFromPem(
              private)); //if we want to sign we use the private one instead and at decryption we use public
      print("Decrypted DES Alice Key " + _msg);
      setState(() {
        Alice_Decrypted_DES = _msg;
      });
      //databaseReference.child("Alice_DES_Keys").set({"DES_Key": msg});
    } else {
      print("Alice DES not recieved");
    }
  }

  void sendChatAlice(String value) {
    TripleDes d = new TripleDes(Bob_DES_key);

    ///Transform this string to divisor of 8:
    if (value.length % 8 == 1) {
      value = value + "       "; //add 7 spaces
    } else if (value.length % 8 == 2) {
      value = value + "      "; //add 6 spaces
    } else if (value.length % 8 == 3) {
      value = value + "     "; //add 5 spaces
    } else if (value.length % 8 == 4) {
      value = value + "    "; //add 4 spaces
    } else if (value.length % 8 == 5) {
      value = value + "   "; //add 3 spaces
    } else if (value.length % 8 == 6) {
      value = value + "  "; //add 2 spaces
    } else if (value.length % 8 == 7) {
      value = value + " "; //add 7 spaces
    }
    String _encryptedM = d.encryptTripleDES(value);
    databaseReference
        .reference()
        .child("chats/bob${DateTime.now().microsecondsSinceEpoch}")
        .set({'bob': _encryptedM});
    usermessage.clear();
  }

  //Not Used
  void deleteData() {
    databaseReference.child('chats').remove();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          "Bob",
        ),
      ),
      body: _loadPublic
          ? Column(
              // mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Center(
                  child: SizedBox(
                    height: 10,
                  ),
                ),
                _hideDetails
                    ? GestureDetector(
                        onTap: () {
                          setState(() {
                            _hideDetails = !_hideDetails;
                          });
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Show Configuration",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Icon(
                              Icons.arrow_drop_down_outlined,
                              color: Colors.black,
                            ),
                          ],
                        ),
                      )
                    : Container(
                        height: 0,
                      ),
                _hideDetails
                    ? Divider(
                        height: 10,
                      )
                    : Container(
                        height: 0,
                      ),
                !_hideDetails
                    ? Text(
                        'Public key is:',
                        style: TextStyle(
                            color: Colors.red, fontWeight: FontWeight.bold),
                      )
                    : Container(
                        height: 0,
                      ),
                !_hideDetails
                    ? Center(
                        child: Text(
                        pub.length > 60 ? pub.toString().substring(0, 60) : pub,
                        style: TextStyle(
                          fontSize: 14,
                        ),
                      ))
                    : Container(
                        height: 0,
                      ),
                !_hideDetails
                    ? Center(
                        child: Divider(
                          height: 10,
                        ),
                      )
                    : Container(
                        height: 0,
                      ),
                !_hideDetails
                    ? Text(
                        'Private key is:',
                        style: TextStyle(
                            color: Colors.red, fontWeight: FontWeight.bold),
                      )
                    : Container(
                        height: 0,
                      ),
                !_hideDetails
                    ? Center(
                        child: Text(
                          private.length > 60
                              ? private.toString().substring(0, 60)
                              : private,
                          style: TextStyle(
                            fontSize: 14,
                          ),
                        ),
                      )
                    : Container(
                        height: 0,
                      ),
                !_hideDetails
                    ? Divider(
                        height: 10,
                      )
                    : Container(
                        height: 0,
                      ),
                !_hideDetails
                    ? Text(
                        "Your DES Key",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 14,
                            color: Colors.red,
                            fontWeight: FontWeight.bold),
                      )
                    : Container(
                        height: 0,
                      ),
                !_hideDetails
                    ? Padding(
                        padding: EdgeInsets.only(top: 5, bottom: 0),
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Icon(
                                Bob_DES_key == ""
                                    ? Icons.error_outlined
                                    : Icons.check_circle_outline_rounded,
                                color: Bob_DES_key == ""
                                    ? Colors.red
                                    : Colors.lightGreen,
                              ),
                              Text(
                                Bob_DES_key == ""
                                    ? "Wait a moment"
                                    : Bob_DES_key,
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ]))
                    : Container(
                        height: 0,
                      ),
                !_hideDetails
                    ? Divider(
                        height: 10,
                      )
                    : Container(
                        height: 0,
                      ),
                !_hideDetails
                    ? Text(
                        "Your Encrypted DES Key",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 14,
                            color: Colors.red,
                            fontWeight: FontWeight.bold),
                      )
                    : Container(
                        height: 0,
                      ),
                !_hideDetails
                    ? Padding(
                        padding: EdgeInsets.only(top: 10, bottom: 0, right: 0),
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Icon(
                                _Encrypted_Bob_DES == ""
                                    ? Icons.error_outlined
                                    : Icons.check_circle_outline_rounded,
                                color: _Encrypted_Bob_DES == ""
                                    ? Colors.red
                                    : Colors.lightGreen,
                              ),
                              Text(
                                _Encrypted_Bob_DES == ""
                                    ? "Alice's Public Key Not Received Yet"
                                    : _Encrypted_Bob_DES.substring(0, 40) +
                                        "....",
                                textAlign: TextAlign.center,
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ]))
                    : Container(
                        height: 0,
                      ),
                !_hideDetails
                    ? Divider(
                        height: 10,
                      )
                    : Container(
                        height: 0,
                      ),
                !_hideDetails
                    ? Text(
                        "Alice's DES Key",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 14,
                            color: Colors.red,
                            fontWeight: FontWeight.bold),
                      )
                    : Container(
                        height: 0,
                      ),
                !_hideDetails
                    ? Padding(
                        padding: EdgeInsets.only(top: 10, bottom: 0),
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Icon(
                                Alice_Decrypted_DES== ""
                                    ? Icons.error_outlined
                                    : Icons.check_circle_outline_rounded,
                                color: Alice_Decrypted_DES== ""
                                    ? Colors.red
                                    : Colors.lightGreen,
                              ),
                              Text(
                                Alice_Decrypted_DES == ""
                                    ? "Not Sent Yet by Alice"
                                    : Alice_Decrypted_DES,
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ]))
                    : Container(
                        height: 0,
                      ),
                !_hideDetails
                    ? Divider(
                        height: 10,
                      )
                    : Container(
                        height: 0,
                      ),
                !_hideDetails
                    ? Text(
                        "Alice's Public Key",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 14,
                            color: Colors.red,
                            fontWeight: FontWeight.bold),
                      )
                    : Container(
                        height: 0,
                      ),
                !_hideDetails
                    ? Padding(
                        padding: EdgeInsets.only(top: 10, bottom: 0),
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Alice_Pub == ""
                                    ? Icons.error_outlined
                                    : Icons.check_circle_outline_rounded,
                                color: Alice_Pub == ""
                                    ? Colors.red
                                    : Colors.lightGreen,
                              ),
                              Text(
                                Alice_Pub == ""
                                    ? "Not Sent Yet by Alice"
                                    : Alice_Pub.substring(0, 60),
                                //  style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ]))
                    : Container(
                        height: 0,
                      ),
                !_hideDetails
                    ? Divider(
                        height: 10,
                      )
                    : Container(
                        height: 0,
                      ),
                !_hideDetails
                    ? GestureDetector(
                        onTap: () {
                          setState(() {
                            _hideDetails = !_hideDetails;
                          });
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Hide Configuration",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Icon(
                              Icons.arrow_drop_up_rounded,
                              color: Colors.black,
                            ),
                          ],
                        ),
                      )
                    : Container(
                        height: 0,
                      ),
                !_hideDetails
                    ? Divider(
                        height: 10,
                      )
                    : Container(
                        height: 0,
                      ),
                Center(
                  child: Text(
                    "End-To-End Encrypted Chat",
                    style: TextStyle(
                        color: Colors.purple,
                        fontSize: 15,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                Flexible(
                  child: new FirebaseAnimatedList(
                      query: databaseReference.reference().child('chats'),
                      itemBuilder: (_, DataSnapshot snapshot,
                          Animation<double> animation, int index) {
                        bool me = snapshot.key.contains("bob") ? true : false;
                        //print(snapshot.key);
                        TripleDes bob_des = new TripleDes(Bob_DES_key);
                        TripleDes alice_des =
                            new TripleDes(Alice_Decrypted_DES);

                        String decMsg = me
                            ? snapshot.value["bob"] != null
                                ? bob_des.decryptTripleDES(
                                    snapshot.value["bob"].toString())
                                : "nothing"
                            : snapshot.value["alice"] != null
                                ? Alice_Decrypted_DES == ""
                                    ?"encrypted"
                                    : alice_des.decryptTripleDES(
                                        snapshot.value["alice"].toString())
                                : "nothing";
                        return Container(
                          child:  decMsg=="encrypted"?Container(height: 0,):Column(
                            crossAxisAlignment: me
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: <Widget>[
                              SizedBox(
                                height: 5,
                              ),
                              Material(
                                color: me
                                    ? Colors.yellow[400]
                                    : Colors.white, //blue[50],
                                borderRadius: BorderRadius.circular(10.0),
                                elevation: 6.0,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      vertical: 10.0, horizontal: 15.0),
                                  child: Text(decMsg),
                                ),
                              )
                            ],
                          ),
                        );
                      }),
                ),
                Row(
                  children: <Widget>[
                    Container(
                      padding: EdgeInsets.only(left: 20, right: 5, bottom: 0),
                      height: 40,
                      width: MediaQuery.of(context).size.width / 1.25,
                      decoration: BoxDecoration(
                        color: Colors.blue[50], //grey[300],
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                      child: TextField(
                        onSubmitted: (value) => usermessage.clear(),
                        decoration: InputDecoration(
                          hintText: "Send a Message...",

                          // border: const OutlineInputBorder(),
                        ),
                        controller: usermessage,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.only(left: 2, right: 0, bottom: 0),
                      height: 40,
                      width: MediaQuery.of(context).size.width -
                          MediaQuery.of(context).size.width / 1.25,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                      child: FlatButton(
                        //borderRadius: BorderRadius.all(Radius.circular(20)),
                        color: Colors.white, //Color(0xFF468499),
                        onPressed: () {
                          if (usermessage.text == "") {
                            print("Empty Message");
                          } else {
                            Bob_DES_key != ""
                                ? sendChatAlice(usermessage.text)
                                : print("You can not send a message.");
                          }
                        },
                        child: Icon(Icons.send, color: Colors.black),
                      ),
                    )
                  ],
                ),
              ],
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(
                    height: 50,
                  ),
                  Padding(
                      padding: EdgeInsets.only(left: 50, right: 50),
                      child: Text(
                        "Generating RSA Keys....",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                      )),
                ],
              ),
            ),
      //This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
