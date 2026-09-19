import 'dart:typed_data';

class ManualAES {
  static const int blockSize = 16; // AES-128 uses 16-byte blocks
  final List<List<int>> _expandedKey;
  final int _rounds = 10; // AES-128 uses 10 rounds

  // S-box lookup table
 static const List<int> _sBox = [
    0x63, 0x7c, 0x77, 0x7b, 0xf2, 0x6b, 0x6f, 0xc5, 0x30, 0x01, 0x67, 0x2b, 0xfe, 0xd7, 0xab, 0x76,
    0xca, 0x82, 0xc9, 0x7d, 0xfa, 0x59, 0x47, 0xf0, 0xad, 0xd4, 0xa2, 0xaf, 0x9c, 0xa4, 0x72, 0xc0,
    0xb7, 0xfd, 0x93, 0x26, 0x36, 0x3f, 0xf7, 0xcc, 0x34, 0xa5, 0xe5, 0xf1, 0x71, 0xd8, 0x31, 0x15,
    0x04, 0xc7, 0x23, 0xc3, 0x18, 0x96, 0x05, 0x9a, 0x07, 0x12, 0x80, 0xe2, 0xeb, 0x27, 0xb2, 0x75,
    0x09, 0x83, 0x2c, 0x1a, 0x1b, 0x6e, 0x5a, 0xa0, 0x52, 0x3b, 0xd6, 0xb3, 0x29, 0xe3, 0x2f, 0x84,
    0x53, 0xd1, 0x00, 0xed, 0x20, 0xfc, 0xb1, 0x5b, 0x6a, 0xcb, 0xbe, 0x39, 0x4a, 0x4c, 0x58, 0xcf,
    0xd0, 0xef, 0xaa, 0xfb, 0x43, 0x4d, 0x33, 0x85, 0x45, 0xf9, 0x02, 0x7f, 0x50, 0x3c, 0x9f, 0xa8,
    0x51, 0xa3, 0x40, 0x8f, 0x92, 0x9d, 0x38, 0xf5, 0xbc, 0xb6, 0xda, 0x21, 0x10, 0xff, 0xf3, 0xd2,
    0xcd, 0x0c, 0x13, 0xec, 0x5f, 0x97, 0x44, 0x17, 0xc4, 0xa7, 0x7e, 0x3d, 0x64, 0x5d, 0x19, 0x73,
    0x60, 0x81, 0x4f, 0xdc, 0x22, 0x2a, 0x90, 0x88, 0x46, 0xee, 0xb8, 0x14, 0xde, 0x5e, 0x0b, 0xdb,
    0xe0, 0x32, 0x3a, 0x0a, 0x49, 0x06, 0x24, 0x5c, 0xc2, 0xd3, 0xac, 0x62, 0x91, 0x95, 0xe4, 0x79,
    0xe7, 0xc8, 0x37, 0x6d, 0x8d, 0xd5, 0x4e, 0xa9, 0x6c, 0x56, 0xf4, 0xea, 0x65, 0x7a, 0xae, 0x08,
    0xba, 0x78, 0x25, 0x2e, 0x1c, 0xa6, 0xb4, 0xc6, 0xe8, 0xdd, 0x74, 0x1f, 0x4b, 0xbd, 0x8b, 0x8a,
    0x70, 0x3e, 0xb5, 0x66, 0x48, 0x03, 0xf6, 0x0e, 0x61, 0x35, 0x57, 0xb9, 0x86, 0xc1, 0x1d, 0x9e,
    0xe1, 0xf8, 0x98, 0x11, 0x69, 0xd9, 0x8e, 0x94, 0x9b, 0x1e, 0x87, 0xe9, 0xce, 0x55, 0x28, 0xdf,
    0x8c, 0xa1, 0x89, 0x0d, 0xbf, 0xe6, 0x42, 0x68, 0x41, 0x99, 0x2d, 0x0f, 0xb0, 0x54, 0xbb, 0x16
  ];

  // Inverse S-box for decryption
 static const List<int> _invSBox = [
    0x52, 0x09, 0x6a, 0xd5, 0x30, 0x36, 0xa5, 0x38, 0xbf, 0x40, 0xa3, 0x9e, 0x81, 0xf3, 0xd7, 0xfb,
    0x7c, 0xe3, 0x39, 0x82, 0x9b, 0x2f, 0xff, 0x87, 0x34, 0x8e, 0x43, 0x44, 0xc4, 0xde, 0xe9, 0xcb,
    0x54, 0x7b, 0x94, 0x32, 0xa6, 0xc2, 0x23, 0x3d, 0xee, 0x4c, 0x95, 0x0b, 0x42, 0xfa, 0xc3, 0x4e,
    0x08, 0x2e, 0xa1, 0x66, 0x28, 0xd9, 0x24, 0xb2, 0x76, 0x5b, 0xa2, 0x49, 0x6d, 0x8b, 0xd1, 0x25,
    0x72, 0xf8, 0xf6, 0x64, 0x86, 0x68, 0x98, 0x16, 0xd4, 0xa4, 0x5c, 0xcc, 0x5d, 0x65, 0xb6, 0x92,
    0x6c, 0x70, 0x48, 0x50, 0xfd, 0xed, 0xb9, 0xda, 0x5e, 0x15, 0x46, 0x57, 0xa7, 0x8d, 0x9d, 0x84,
    0x90, 0xd8, 0xab, 0x00, 0x8c, 0xbc, 0xd3, 0x0a, 0xf7, 0xe4, 0x58, 0x05, 0xb8, 0xb3, 0x45, 0x06,
    0xd0, 0x2c, 0x1e, 0x8f, 0xca, 0x3f, 0x0f, 0x02, 0xc1, 0xaf, 0xbd, 0x03, 0x01, 0x13, 0x8a, 0x6b,
    0x3a, 0x91, 0x11, 0x41, 0x4f, 0x67, 0xdc, 0xea, 0x97, 0xf2, 0xcf, 0xce, 0xf0, 0xb4, 0xe6, 0x73,
    0x96, 0xac, 0x74, 0x22, 0xe7, 0xad, 0x35, 0x85, 0xe2, 0xf9, 0x37, 0xe8, 0x1c, 0x75, 0xdf, 0x6e,
    0x47, 0xf1, 0x1a, 0x71, 0x1d, 0x29, 0xc5, 0x89, 0x6f, 0xb7, 0x62, 0x0e, 0xaa, 0x18, 0xbe, 0x1b,
    0xfc, 0x56, 0x3e, 0x4b, 0xc6, 0xd2, 0x79, 0x20, 0x9a, 0xdb, 0xc0, 0xfe, 0x78, 0xcd, 0x5a, 0xf4,
    0x1f, 0xdd, 0xa8, 0x33, 0x88, 0x07, 0xc7, 0x31, 0xb1, 0x12, 0x10, 0x59, 0x27, 0x80, 0xec, 0x5f,
    0x60, 0x51, 0x7f, 0xa9, 0x19, 0xb5, 0x4a, 0x0d, 0x2d, 0xe5, 0x7a, 0x9f, 0x93, 0xc9, 0x9c, 0xef,
    0xa0, 0xe0, 0x3b, 0x4d, 0xae, 0x2a, 0xf5, 0xb0, 0xc8, 0xeb, 0xbb, 0x3c, 0x83, 0x53, 0x99, 0x61,
    0x17, 0x2b, 0x04, 0x7e, 0xba, 0x77, 0xd6, 0x26, 0xe1, 0x69, 0x14, 0x63, 0x55, 0x21, 0x0c, 0x7d
  ];

  // Round constants
  static const List<int> _rcon = [
    0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80, 0x1b, 0x36
  ];

  ManualAES(List<int> key) : _expandedKey = _keyExpansion(key) {
    if (key.length != 16) { // AES-128 uses 16-byte key
      throw ArgumentError('AES-128 requires a 16-byte key');
    }
  }

  // Key expansion algorithm
  static List<List<int>> _keyExpansion(List<int> key) {
    final expandedKey = List.generate(44, (_) => List<int>.filled(4, 0));
    
    // Copy the initial key
    for (int i = 0; i < 4; i++) {
      expandedKey[i] = [
        key[4 * i],
        key[4 * i + 1], 
        key[4 * i + 2],
        key[4 * i + 3]
      ];
    }

    // Generate the expanded key schedule
    for (int i = 4; i < 44; i++) {
      var temp = List<int>.from(expandedKey[i - 1]);
      
      if (i % 4 == 0) {
        // RotWord operation
        final t = temp[0];
        temp[0] = temp[1];
        temp[1] = temp[2];
        temp[2] = temp[3];
        temp[3] = t;

        // SubWord operation
        for (int j = 0; j < 4; j++) {
          temp[j] = _sBox[temp[j]];
        }

        // XOR with round constant
        temp[0] ^= _rcon[i ~/ 4 - 1];
      }

      // XOR with previous word
      for (int j = 0; j < 4; j++) {
        expandedKey[i][j] = expandedKey[i - 4][j] ^ temp[j];
      }
    }

    return expandedKey;
  }

  // Single block encryption
  List<int> encryptBlock(List<int> block) {
    if (block.length != blockSize) {
      throw ArgumentError('Block size must be $blockSize bytes');
    }

    var state = List<int>.from(block);
    
    // Initial AddRoundKey
    state = _addRoundKey(state, 0);

    // Main rounds
    for (int round = 1; round < _rounds; round++) {
      state = _subBytes(state);
      state = _shiftRows(state);
      state = _mixColumns(state);
      state = _addRoundKey(state, round);
    }

    // Final round (no MixColumns)
    state = _subBytes(state);
    state = _shiftRows(state);
    state = _addRoundKey(state, _rounds);

    return state;
  }

  // Single block decryption
  List<int> decryptBlock(List<int> block) {
    if (block.length != blockSize) {
      throw ArgumentError('Block size must be $blockSize bytes');
    }

    var state = List<int>.from(block);
    
    // Inverse operations in reverse order
    state = _addRoundKey(state, _rounds);
    state = _invShiftRows(state);
    state = _invSubBytes(state);

    for (int round = _rounds - 1; round > 0; round--) {
      state = _addRoundKey(state, round);
      state = _invMixColumns(state);
      state = _invShiftRows(state);
      state = _invSubBytes(state);
    }

    state = _addRoundKey(state, 0);
    
    return state;
  }

  // AES SubBytes transformation
  List<int> _subBytes(List<int> state) {
    return state.map((byte) => _sBox[byte]).toList();
  }

  // AES Inverse SubBytes
  List<int> _invSubBytes(List<int> state) {
    return state.map((byte) => _invSBox[byte]).toList();
  }

  // AES ShiftRows transformation
  List<int> _shiftRows(List<int> state) {
    return [
      state[0], state[5], state[10], state[15],
      state[4], state[9], state[14], state[3],
      state[8], state[13], state[2], state[7],
      state[12], state[1], state[6], state[11]
    ];
  }

  // AES Inverse ShiftRows
  List<int> _invShiftRows(List<int> state) {
    return [
      state[0], state[13], state[10], state[7],
      state[4], state[1], state[14], state[11],
      state[8], state[5], state[2], state[15],
      state[12], state[9], state[6], state[3]
    ];
  }

  // AES MixColumns transformation
  List<int> _mixColumns(List<int> state) {
    final result = List<int>.filled(16, 0);
    
    for (int i = 0; i < 4; i++) {
      final int col = i * 4;
      result[col] = _gmul(2, state[col]) ^ _gmul(3, state[col + 1]) ^ 
                    state[col + 2] ^ state[col + 3];
      result[col + 1] = state[col] ^ _gmul(2, state[col + 1]) ^ 
                        _gmul(3, state[col + 2]) ^ state[col + 3];
      result[col + 2] = state[col] ^ state[col + 1] ^ 
                        _gmul(2, state[col + 2]) ^ _gmul(3, state[col + 3]);
      result[col + 3] = _gmul(3, state[col]) ^ state[col + 1] ^ 
                        state[col + 2] ^ _gmul(2, state[col + 3]);
    }
    
    return result;
  }

  // AES Inverse MixColumns
  List<int> _invMixColumns(List<int> state) {
    final result = List<int>.filled(16, 0);
    
    for (int i = 0; i < 4; i++) {
      final int col = i * 4;
      result[col] = _gmul(0x0e, state[col]) ^ _gmul(0x0b, state[col + 1]) ^
                    _gmul(0x0d, state[col + 2]) ^ _gmul(0x09, state[col + 3]);
      result[col + 1] = _gmul(0x09, state[col]) ^ _gmul(0x0e, state[col + 1]) ^
                        _gmul(0x0b, state[col + 2]) ^ _gmul(0x0d, state[col + 3]);
      result[col + 2] = _gmul(0x0d, state[col]) ^ _gmul(0x09, state[col + 1]) ^
                        _gmul(0x0e, state[col + 2]) ^ _gmul(0x0b, state[col + 3]);
      result[col + 3] = _gmul(0x0b, state[col]) ^ _gmul(0x0d, state[col + 1]) ^
                        _gmul(0x09, state[col + 2]) ^ _gmul(0x0e, state[col + 3]);
    }
    
    return result;
  }

  // Galois Field multiplication
  int _gmul(int a, int b) {
    int p = 0;
    for (int counter = 0; counter < 8; counter++) {
      if ((b & 1) != 0) {
        p ^= a;
      }
      bool hibit = (a & 0x80) != 0;
      a <<= 1;
      if (hibit) {
        a ^= 0x1b;
      }
      b >>= 1;
    }
    return p & 0xff;
  }

  // AddRoundKey transformation
  List<int> _addRoundKey(List<int> state, int round) {
    final result = List<int>.filled(16, 0);
    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 4; j++) {
        result[i * 4 + j] = state[i * 4 + j] ^ _expandedKey[round * 4 + i][j];
      }
    }
    return result;
  }

  // PKCS7 padding
  static List<int> _pkcs7Pad(List<int> data, int blockSize) {
    final padLength = blockSize - (data.length % blockSize);
    return [...data, ...List.filled(padLength, padLength)];
  }

  // Remove PKCS7 padding
  static List<int> _pkcs7Unpad(List<int> data) {
    final padLength = data.last;
    if (padLength <= 0 || padLength > blockSize) {
      throw FormatException('Invalid PKCS7 padding');
    }
    
    // Verify padding
    for (int i = data.length - padLength; i < data.length; i++) {
      if (data[i] != padLength) {
        throw FormatException('Invalid PKCS7 padding');
      }
    }
    
    return data.sublist(0, data.length - padLength);
  }

  // CBC mode encryption
  List<int> encryptCBC(List<int> data, List<int> iv) {
    if (iv.length != blockSize) {
      throw ArgumentError('IV must be $blockSize bytes');
    }
    
    final paddedData = _pkcs7Pad(data, blockSize);
    final result = <int>[];
    var previousBlock = List<int>.from(iv);
    
    for (var i = 0; i < paddedData.length; i += blockSize) {
      final block = paddedData.sublist(i, i + blockSize);
      
      // XOR with previous block
      for (var j = 0; j < blockSize; j++) {
        block[j] ^= previousBlock[j];
      }
      
      final encrypted = encryptBlock(block);
      result.addAll(encrypted);
      previousBlock = encrypted;
    }
    
    return result;
  }

  // CBC mode decryption
  List<int> decryptCBC(List<int> data, List<int> iv) {
    if (data.length % blockSize != 0) {
      throw ArgumentError('Invalid ciphertext length');
    }
    
    final result = <int>[];
    var previousBlock = List<int>.from(iv);
    
    for (var i = 0; i < data.length; i += blockSize) {
      final block = data.sublist(i, i + blockSize);
      final decrypted = decryptBlock(List<int>.from(block));
      
      // XOR with previous block
      for (var j = 0; j < blockSize; j++) {
        decrypted[j] ^= previousBlock[j];
      }
      
      result.addAll(decrypted);
      previousBlock = block;
    }
    
    return _pkcs7Unpad(result);
  }
}