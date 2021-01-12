import 'dart:convert';
import 'package:convert/convert.dart';
import 'DES_Helper.dart';

class TripleDes {
  String _key;
  String _message;

  TripleDes(String key) {
    this._key = key;
//    this._message=message;
   // print('key: $key');
    // print('message: $message');
  }

  String get key => _key;

  set key(String value) {
    _key = value;
  }

  //String key = _key;//'12345678'; // 8-byte
  //String message = 'Driving in from the edge of town';
  List<int> encrypted;
  List<int> decrypted;
  List<int> iv = [1, 2, 3, 4, 5, 6, 7, 8]; //initial vector

   String encryptTripleDES(String ToBeEncrypted) {
    //key = '123456781234567812345678'; // 24-byte=>192 bits in 3DES
    DES3 des3CBC = DES3(key: key.codeUnits, mode: DESMode.CBC, iv: iv);
    encrypted = des3CBC.encrypt(ToBeEncrypted.codeUnits);
    //decrypted = des3CBC.decrypt(encrypted);
    print('Triple DES mode: CBC');
    print('encrypted: $encrypted');
   // print('encrypted (hex): ${hex.encode(encrypted)}');
   print('encrypted (base64): ${base64.encode(encrypted)}');

    return base64.encode(encrypted);//return Encrypted Message;
  }
String decryptTripleDES(String Encrypted){
  DES3 des3CBC = DES3(key: key.codeUnits, mode: DESMode.CBC, iv: iv);
  //encrypted = des3CBC.encrypt(message.codeUnits);
  decrypted = des3CBC.decrypt(base64.decode(Encrypted));
  print('decrypted: $decrypted');
  //print('decrypted (hex): ${hex.encode(decrypted)}');
  print('decrypted (utf8): ${utf8.decode(decrypted)}');

  return utf8.decode(decrypted);// return Decrypted message
}
  String get message => _message;

  set message(String value) {
    _message = value;
  }
}
