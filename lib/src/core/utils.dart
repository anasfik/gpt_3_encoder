import 'dart:convert';
import 'dart:math';

abstract class GPT3EncoderUtils {
  /// generates a new List of integers from x to y (exclusive)
  static List<int> range(int x, int y) {
    List<int> res = List<int>.generate(y, (index) => index);
    res = res.sublist(x);
    return res;
  }

  ///  Returns the unicode code point of a character
  static int ord(String char) {
    return char.codeUnitAt(0);
  }

  /// Returns the character of a unicode code point
  static String chr(int x) {
    return String.fromCharCode(x);
  }

  /// The UTF-8 encoder.
  static final textEncoder = utf8;

  /// Encodes a string into a list of integers
  static List<int> encodeStr(String str) {
    final encoded = textEncoder.encode(str);

    return encoded;
  }

  /// The UTF-8 decoder.
  static final textDecoder = utf8;

  /// Decodes a list of integers into a string
  static String decodeStr(List arr) {
    return textDecoder.decode(
      arr.cast<int>(),
      allowMalformed: true,
    );
  }

  static bool isNaN(dynamic x) {
    return x == null || x.isNaN;
  }

  static num minimum(Iterable<num> nums) => nums.reduce(min);

  static final pat = RegExp(
    r"'s|'t|'re|'ve|'m|'ll|'d| ?\p{L}+| ?\p{N}+| ?[^\s\p{L}\p{N}]+|\s+(?!\S)|\s+",
    unicode: true,
    dotAll: true,
  );
}
