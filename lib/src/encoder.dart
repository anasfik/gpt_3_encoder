import 'package:gpt_3_encoder/src/core/bpe.dart';

import 'core/encoding_handler.dart';
import 'core/utils.dart';

/// {@template gpt3_encoder}
/// This class can be used to encode/decode text for use with GPT models provided by OpenAI.
/// {@endtemplate}
class GPT3Encoder {
  /// {@macro gpt3_encoder}
  static final GPT3Encoder _instance = GPT3Encoder._();

  /// {@macro gpt3_encoder}
  static GPT3Encoder get instance => _instance;

  /// {@macro gpt3_encoder_bpe}
  final _bpe = GPT3EncoderBpe();

  /// {@macro gpt3_encoder_handler}
  final _encodingHandler = GPT3EncoderHandler();

  /// Decodes a the given [tokens] into a string.
  ///
  /// ```dart
  /// final text = 'Hello World!';
  ///
  /// final encoded = GPT3Encoder.instance.encode(text);
  /// final decoded = GPT3Encoder.instance.decode(tokens);
  ///
  /// print(decoded); // Hello World!
  String decode(List<int> tokens) {
    dynamic text = tokens.map((x) => _bpe.decoder![x]).join('');

    final splitted = text.split('');
    text = GPT3EncoderUtils.decodeStr(splitted.map((x) {
      final encoded = _encodingHandler.byteDecoder![x];
      return encoded as int;
    }).toList());
    return text;
  }

  /// Encodes a give, [text] into a list of tokens.
  ///
  /// ```dart
  /// final text = 'Hello World!';
  /// final tokens = GPT3Encoder.instance.encode(text);
  /// print(tokens); // [15496, 2159, 0]
  /// ```
  List<int> encode(String text) {
    List<int> bpeTokens = [];
    final matches =
        GPT3EncoderUtils.pat.allMatches(text).map((x) => x.group(0)).toList();
    for (var token in matches) {
      final encoded = GPT3EncoderUtils.encodeStr(token!);
      final localToken = encoded.map((x) {
        final encoded = _encodingHandler.byteEncoder![x];
        return encoded;
      }).join('');

      final newTokens =
          _bpe(localToken).split(' ').map((x) => _bpe.encoder![x]).toList();

      bpeTokens = bpeTokens.followedBy(newTokens.cast()).toList();
    }

    return bpeTokens;
  }

  /// {@macro gpt3_encoder}
  GPT3Encoder._();
}
