import 'dart:convert';
import 'DES_Helper.dart';

class TripleDes {
  String _key;
  String _message;

  TripleDes(String key) {
    this._key = key;
  }

  String get key => _key;

  set key(String value) {
    _key = value;
  }


  List<int> encrypted;
  List<int> decrypted;
  List<int> iv = [1, 2, 3, 4, 5, 6, 7, 8]; //initial vector

  String encryptTripleDES(String ToBeEncrypted) {
    DES3 des3CBC = DES3(key: key.codeUnits, mode: DESMode.CBC, iv: iv);
    encrypted = des3CBC.encrypt(ToBeEncrypted.codeUnits);
    print('Triple DES mode: CBC');
    print('encrypted: $encrypted');
    print('encrypted (base64): ${base64.encode(encrypted)}');

    return base64.encode(encrypted); //return Encrypted Message;
  }

  String decryptTripleDES(String Encrypted) {
    bool error = false;
    String output = "";
    DES3 des3CBC = DES3(key: key.codeUnits, mode: DESMode.CBC, iv: iv);
    try {
      //encrypted = des3CBC.encrypt(message.codeUnits);
      decrypted = des3CBC.decrypt(base64.decode(Encrypted));
      // print('decrypted (utf8): ${utf8.decode(decrypted)}');
      output = utf8.decode(decrypted);
    } catch (Exception) {
      print(Exception.toString());
      error = true;
    }
    return error ? "encrypted" : output; // return Decrypted message
  }

  String get message => _message;

  set message(String value) {
    _message = value;
  }
}
