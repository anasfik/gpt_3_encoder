import 'dart:math';

import 'utils.dart';

/// {@template gpt3_encoder_handler}
/// This class will be responsible to manage and handle the bytes encoding for the [GPT3Encoder].
/// {@endtemplate}
class GPT3EncoderHandler {
  /// Holds the encoded bytes.
  Map<int, String>? byteEncoder;

  /// Holds the decoded bytes.
  Map<String, int>? byteDecoder;

  static Map<int, String> bytesToUnicode() {
    final bs = GPT3EncoderUtils.range(
            GPT3EncoderUtils.ord('!'), GPT3EncoderUtils.ord('~') + 1)
        .followedBy(GPT3EncoderUtils.range(
            GPT3EncoderUtils.ord('¡'), GPT3EncoderUtils.ord('¬') + 1))
        .followedBy(GPT3EncoderUtils.range(
            GPT3EncoderUtils.ord('®'), GPT3EncoderUtils.ord('ÿ') + 1))
        .toList();
    List<dynamic> cs = bs.sublist(0);
    int n = 0;

    for (int b = 0; b < pow(2, 8); b++) {
      if (!bs.contains(b)) {
        bs.add(b);
        cs.add(pow(2, 8).toInt() + n);
        n = n + 1;
      }
    }

    cs = cs.map((x) => GPT3EncoderUtils.chr(x)).toList();
    final result = <int, String>{};

    bs.asMap().forEach(
      (i, _) {
        final elem = bs[i];
        final sElem = cs[i];
        result[elem] = sElem;
      },
    );

    // for (int i = 0; i < bs.length; i++) {
    //   result[bs[i]] = cs[i];
    // }

    return result;
  }

  /// {@macro gpt3_encoder_handler}
  GPT3EncoderHandler() {
    byteEncoder = bytesToUnicode();
    byteDecoder = {};
    for (var x in byteEncoder!.keys) {
      byteDecoder![byteEncoder![x]!] = x;
    }
  }
}
