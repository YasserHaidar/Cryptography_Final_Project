import 'dart:convert';
import 'dart:math';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:flutter/material.dart';
import 'package:rsa_encrypt/rsa_encrypt.dart';
import 'package:pointycastle/api.dart' as crypto;
import 'package:secure_chat/des_manager.dart';
import 'package:firebase_database/firebase_database.dart';
import 'Bob.dart';

class Alice extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

TripleDes d;
//String Bob_DES_key = "968314835893053678736231"; // for Bob
String Alice_DES_key = "748394061928487102845723"; // for Alice
final databaseReference = FirebaseDatabase.instance.reference();

class _MyHomePageState extends State<Alice> {
  TextEditingController usermessage;
  DatabaseReference BobKeys;
  DatabaseReference BobDES;
  @override
  void initState() {
    setState(() {
      Alice_DES_key = CreateCryptoRandomString().substring(0,24);
      getKey();
    });
    usermessage = new TextEditingController();
    BobKeys = databaseReference.child('Bob_Pub_Keys');
    BobKeys.onChildAdded.listen(_onBobKeyAdded);
    BobKeys.onChildChanged.listen(_onBobKeyAdded);
    BobDES = databaseReference.child('Bob_DES_Keys');
    BobDES.onChildAdded.listen(_onBobDESAdded);
    BobDES.onChildChanged.listen(_onBobDESAdded);

    super.initState();
  }

  @override
  void dispose() {
    // channel.sink.close();
    super.dispose();
  }

  final List<String> list = [];
  bool _loadPublic = false;
  String Bob_Public = "";
  String Alice_pub = "Not Generated Yet";
  String Alice_private = "Not Generated Yet";
  String Recieved_DES_Bob_Key = "";
  String Bob_Decrypted_DES = "";
  bool _hideDetails = true;
  String _Encrypted_Alice_DES = "";

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
    Alice_pub = helper.encodePublicKeyToPemPKCS1(keyPair.publicKey);
    Alice_private = helper.encodePrivateKeyToPemPKCS1(keyPair.privateKey);
    setState(() {
      _loadPublic = true;
    });
    sendPubKey();
  }

  ///Real Time Database:

  _onBobKeyAdded(Event event) {
    //print(event.snapshot.value);
    print("Bob Public Key Recieved");
    setState(() {
      Bob_Public = event.snapshot.value;
    });
    sendAliceDESKey();
  }

  _onBobDESAdded(Event event) {
    // print(event.snapshot.value);
    setState(() {
      Recieved_DES_Bob_Key = event.snapshot.value;
    });
    decryptSenderDESKey();
  }

  sendPubKey() {
    //channel.sink.add("Alice Pub Key" + pub.substring(0, 40));
    if (Alice_pub != "") {
      databaseReference.child("Alice_Pub_Keys").set({'Pub_Key': Alice_pub});
    } else {
      print("Public key not retrieved yet!");
    }
  }

  sendAliceDESKey() {
    print("Encrypting Alice DES Key");
    //print(Bob_Public);
    var helper = RsaKeyHelper();
    String msg = encrypt(
        Alice_DES_key,
        helper.parsePublicKeyFromPem(
            Bob_Public)); //if we want to sign we use the private one instead and at decryption we use public
    //TODO:In the report write that we can add the feature of signature to verify that this message is coming from Alice really
    //print(msg);
    setState(() {
      _Encrypted_Alice_DES = msg;
    });
    databaseReference.child("Alice_DES_Keys").set({"DES_Key": msg});
  }

  decryptSenderDESKey() {
    //print(Recieved_DES_Bob_Key);
    if (Recieved_DES_Bob_Key != "" && Alice_private != "Not Generated Yet") {
      var helper = RsaKeyHelper();
      String msg = decrypt(
          Recieved_DES_Bob_Key,
          helper.parsePrivateKeyFromPem(
              Alice_private)); //if we want to sign we use the private one instead and at decryption we use public
      print("Alice Private Key " + msg);
      setState(() {
        Bob_Decrypted_DES = msg;
      });
      //databaseReference.child("Alice_DES_Keys").set({"DES_Key": msg});
    } else {
      print("Bob DES not recieved");
    }
  }

  sendChatBob(String value) {
    TripleDes d = new TripleDes(Alice_DES_key);

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
        .child("chats/alice${DateTime.now().microsecondsSinceEpoch}")
        .set({'alice': _encryptedM});
    usermessage.clear();
  }

  static final Random _random = Random.secure();

  String CreateCryptoRandomString([int length = 16]) {
    var values = List<int>.generate(length, (i) => _random.nextInt(256));
    print(base64Url.encode(values));

    return base64Url.encode(values);
  }

  void deleteData() {
    databaseReference.child('chats').remove();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          "Alice",
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
                        Alice_pub.length > 60
                            ? Alice_pub.toString().substring(0, 60)
                            : Alice_pub,
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
                          Alice_private.length > 60
                              ? Alice_private.toString().substring(0, 60)
                              : Alice_private,
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
                                Alice_DES_key == ""
                                    ? Icons.error_outlined
                                    : Icons.check_circle_outline_rounded,
                                color: Alice_DES_key == ""
                                    ? Colors.red
                                    : Colors.lightGreen,
                              ),
                              Text(
                                Alice_DES_key == ""
                                    ? "Wait a moment"
                                    : Alice_DES_key,
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
                                _Encrypted_Alice_DES == ""
                                    ? Icons.error_outlined
                                    : Icons.check_circle_outline_rounded,
                                color: _Encrypted_Alice_DES == ""
                                    ? Colors.red
                                    : Colors.lightGreen,
                              ),
                              Text(
                                _Encrypted_Alice_DES == ""
                                    ? "Bob's Public Key Not Received Yet"
                                    : _Encrypted_Alice_DES.substring(0, 40) +
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
                        "Bob's DES Key",
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
                                Bob_Decrypted_DES == ""
                                    ? Icons.error_outlined
                                    : Icons.check_circle_outline_rounded,
                                color: Bob_Decrypted_DES == ""
                                    ? Colors.red
                                    : Colors.lightGreen,
                              ),
                              Text(
                                Bob_Decrypted_DES == ""
                                    ? "Not Sent Yet by Bob"
                                    : Bob_Decrypted_DES + "....",
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
                        "Bob's Public Key",
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
                                Bob_Public == ""
                                    ? Icons.error_outlined
                                    : Icons.check_circle_outline_rounded,
                                color: Bob_Public == ""
                                    ? Colors.red
                                    : Colors.lightGreen,
                              ),
                              Text(
                                Bob_Public == ""
                                    ? "Not Sent Yet by Bob"
                                    : Bob_Public.substring(0, 60),
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
                        bool me = snapshot.key.contains("alice") ? true : false;
                        //print(snapshot.key);
                        TripleDes bob_des = new TripleDes(Bob_Decrypted_DES);
                        TripleDes alice_des = new TripleDes(Alice_DES_key);
                        String decMsg = me
                            ? snapshot.value["alice"] != null
                                ? alice_des.decryptTripleDES(
                                    snapshot.value["alice"].toString())
                                : "nothing"
                            : snapshot.value["bob"] != null
                                ? Bob_Decrypted_DES == ""
                                    ? "encrypted"
                                    : bob_des.decryptTripleDES(
                                        snapshot.value["bob"].toString())
                                : "nothing";
                        return Container(
                          child:
                          decMsg=="encrypted"?
                              Container(height: 0,):
                          Column(
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
                            Alice_DES_key != ""
                                ? sendChatBob(usermessage.text)
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

      /* floatingActionButton: FloatingActionButton(
        onPressed: switchtoBob,
        tooltip: 'Bob',
        child: Icon(Icons.person),
      ),*/ // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
