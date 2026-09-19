import 'dart:convert';

class Base64Caesar {
  static List<int> encrypt(List<int> data, int shift) {
    // Convert to base64
    final base64Str = base64.encode(data);
    final result = <int>[];
    
    // Apply Caesar shift
    for (var i = 0; i < base64Str.length; i++) {
      final char = base64Str.codeUnitAt(i);
      
      if ((char >= 65 && char <= 90) || (char >= 97 && char <= 122)) {
        final base = (char >= 65 && char <= 90) ? 65 : 97;
        result.add((char - base + shift) % 26 + base);
      } else {
        result.add(char);
      }
    }
    
    return result;
  }
  
  static List<int> decrypt(List<int> data, int shift) {
    final decrypted = <int>[];
    
    // Reverse Caesar shift
    for (var i = 0; i < data.length; i++) {
      final char = data[i];
      
      if ((char >= 65 && char <= 90) || (char >= 97 && char <= 122)) {
        final base = (char >= 65 && char <= 90) ? 65 : 97;
        decrypted.add((char - base - shift + 26) % 26 + base);
      } else {
        decrypted.add(char);
      }
    }
    
    // Decode base64
    final decryptedStr = String.fromCharCodes(decrypted);
    return base64.decode(decryptedStr);
  }
}