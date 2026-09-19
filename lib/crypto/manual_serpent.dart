import 'dart:typed_data';

class ManualSerpent {
  static const int blockSize = 16;
  static const int rounds = 32;
  final List<List<int>> _roundKeys;

  // S-boxes (8 different 4x4 S-boxes)
  static const List<List<int>> _sBox = [
    // S0
    [3, 8, 15, 1, 10, 6, 5, 11, 14, 13, 4, 2, 7, 0, 9, 12],
    // S1
    [15, 12, 2, 7, 9, 0, 5, 10, 1, 11, 14, 8, 6, 13, 3, 4],
    // S2 
    [8, 6, 7, 9, 3, 12, 10, 15, 13, 1, 14, 4, 0, 11, 5, 2],
    // S3
    [0, 15, 11, 8, 12, 9, 6, 3, 13, 1, 2, 4, 10, 7, 5, 14],
    // S4
    [1, 15, 8, 3, 12, 0, 11, 6, 2, 5, 4, 10, 9, 14, 7, 13],
    // S5
    [15, 5, 2, 11, 4, 10, 9, 12, 0, 3, 14, 8, 13, 6, 7, 1],
    // S6
    [7, 2, 12, 5, 8, 4, 6, 11, 14, 9, 1, 15, 13, 3, 10, 0],
    // S7
    [1, 13, 15, 0, 14, 8, 2, 11, 7, 4, 12, 10, 9, 3, 5, 6]
  ];

  // Inverse S-boxes for decryption
  static const List<List<int>> _invSBox = [
    // Inverse S0
    [13, 3, 11, 0, 10, 6, 5, 12, 1, 14, 4, 7, 15, 9, 8, 2],
    // Inverse S1 
    [5, 8, 2, 14, 15, 6, 12, 3, 11, 4, 7, 9, 1, 13, 10, 0],
    // Inverse S2
    [12, 9, 15, 4, 11, 14, 1, 2, 0, 3, 6, 13, 5, 8, 10, 7],
    // Inverse S3
    [0, 9, 10, 7, 11, 14, 6, 13, 3, 5, 12, 2, 4, 8, 15, 1],
    // Inverse S4
    [5, 0, 8, 3, 10, 9, 7, 14, 2, 12, 11, 6, 4, 15, 13, 1],
    // Inverse S5
    [8, 15, 2, 9, 4, 1, 13, 14, 11, 6, 5, 3, 7, 12, 10, 0],
    // Inverse S6
    [15, 10, 1, 13, 5, 3, 6, 0, 4, 9, 14, 7, 2, 12, 8, 11],
    // Inverse S7
    [2, 0, 6, 13, 11, 12, 15, 8, 5, 3, 14, 7, 4, 10, 1, 9]
  ];

  ManualSerpent(List<int> key) : _roundKeys = _generateRoundKeys(key) {
    if (key.length != 32) {
      throw ArgumentError('Serpent requires a 32-byte key');
    }
  }

  // Key schedule generation
 static List<List<int>> _generateRoundKeys(List<int> key) {
  final prekeys = List<int>.filled(140, 0);
  final roundKeys = List.generate(33, (_) => List<int>.filled(4, 0));

  // Convert key to words (32-bit)
  final words = List<int>.filled(8, 0);
  for (int i = 0; i < 8; i++) {
    words[i] = (i < key.length ~/ 4) 
      ? ((key[4*i] & 0xff) | 
         ((key[4*i + 1] & 0xff) << 8) | 
         ((key[4*i + 2] & 0xff) << 16) | 
         ((key[4*i + 3] & 0xff) << 24))
      : 0;
  }

  // Generate prekeys
  for (int i = 0; i < 132; i++) {
    prekeys[i + 8] = _rotateLeft(
      prekeys[i + 7] ^ prekeys[i + 2] ^ prekeys[i + 1] ^ prekeys[i] ^ 0x9e3779b9 ^ i,
      11
    );
  }

  // Apply S-boxes to get round keys
  for (int i = 0; i < 33; i++) {
    final sboxIndex = (32 + 3 - i) % 8;
    var t = List<int>.filled(4, 0);
    
    // Extract 128 bits
    for (int j = 0; j < 4; j++) {
      t[j] = prekeys[4 * i + j + 8];
    }

    // Apply S-box
    t = _applySBoxToWords(t, sboxIndex);

    // Store round key
    for (int j = 0; j < 4; j++) {
      roundKeys[i][j] = t[j];
    }
  }

  return roundKeys;
}

// Helper function to apply S-box to 32-bit words
static List<int> _applySBoxToWords(List<int> words, int sboxIndex) {
  final result = List<int>.filled(4, 0);
  final sbox = _sBox[sboxIndex];

  for (int i = 0; i < 4; i++) {
    int x = words[i];
    int y = 0;

    // Apply S-box to each nibble
    for (int j = 0; j < 8; j++) {
      y |= ((sbox[(x >> (4 * j)) & 0xf]) & 0xf) << (4 * j);
    }

    result[i] = y;
  }

  return result;
}

// Rotate left operation
static int _rotateLeft(int value, int shift) {
  return ((value << shift) | ((value >> (32 - shift)))) & 0xFFFFFFFF;
}

// Rotate right operation
static int _rotateRight(int value, int shift) {
  return ((value >> shift) | ((value << (32 - shift)))) & 0xFFFFFFFF;
}

  // Single block encryption
  List<int> encryptBlock(List<int> block) {
    if (block.length != blockSize) {
      throw ArgumentError('Block size must be $blockSize bytes');
    }

    var state = List<int>.from(block);

    // Initial permutation
    state = _initialPermutation(state);

    // 32 rounds
    for (int i = 0; i < rounds; i++) {
      state = _round(state, _roundKeys[i], i % 8);
    }

    // Final permutation
    state = _finalPermutation(state);

    return state;
  }

  // Single block decryption
  List<int> decryptBlock(List<int> block) {
    if (block.length != blockSize) {
      throw ArgumentError('Block size must be $blockSize bytes');
    }

    var state = List<int>.from(block);

    // Initial permutation
    state = _initialPermutation(state);

    // 32 rounds in reverse
    for (int i = rounds - 1; i >= 0; i--) {
      state = _inverseRound(state, _roundKeys[i], i % 8);
    }

    // Final permutation
    state = _finalPermutation(state);

    return state;
  }

  // Round function
  List<int> _round(List<int> state, List<int> roundKey, int sboxIndex) {
    // Apply S-box
    state = _applySBox(state, _sBox[sboxIndex]);
    
    // Linear transformation
    state = _linearTransformation(state);
    
    // Add round key
    for (int i = 0; i < blockSize; i++) {
      state[i] ^= roundKey[i];
    }
    
    return state;
  }

  // Inverse round function
  List<int> _inverseRound(List<int> state, List<int> roundKey, int sboxIndex) {
    // Remove round key
    for (int i = 0; i < blockSize; i++) {
      state[i] ^= roundKey[i];
    }
    
    // Inverse linear transformation
    state = _inverseLinearTransformation(state);
    
    // Apply inverse S-box
    state = _applySBox(state, _invSBox[sboxIndex]);
    
    return state;
  }

  // Initial and final permutations
  List<int> _initialPermutation(List<int> block) {
    // Implement initial permutation
    return block; // Placeholder
  }

  List<int> _finalPermutation(List<int> block) {
    // Implement final permutation
    return block; // Placeholder
  }

  // S-box application
  List<int> _applySBox(List<int> state, List<int> sbox) {
  final result = List<int>.filled(blockSize, 0);
  
  // Process each byte in the state
  for (int i = 0; i < blockSize; i++) {
    // Split byte into two nibbles (4-bit values)
    int highNibble = (state[i] >> 4) & 0x0F;  // Get high 4 bits
    int lowNibble = state[i] & 0x0F;          // Get low 4 bits
    
    // Apply S-box substitution to each nibble
    highNibble = sbox[highNibble];
    lowNibble = sbox[lowNibble];
    
    // Combine nibbles back into a byte
    result[i] = (highNibble << 4) | lowNibble;
  }
  
  return result;
}

  // Linear transformation
  List<int> _linearTransformation(List<int> state) {
    // Implement linear transformation
    return state; // Placeholder
  }

  List<int> _inverseLinearTransformation(List<int> state) {
    // Implement inverse linear transformation
    return state; // Placeholder
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