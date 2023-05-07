# GPT 3 Encoder

This package aims to provide a simple interface for encoding and decoding text same as GPT-3, GPT-2 that uses byte pair encoding (BPE) to turn text into a series of integers to feed into the models.

This package is a pure Dart implementation of OpenAI's original Python encoder/decoder.

## Usage

```dart
import 'package:gpt_3_encoder/gpt_3_encoder.dart';

void main() {
  // This is the text we want to encode and decode.
  final text = "Hello World!";

  // Encode the text.
  final encoded = GPT3Encoder.instance.encode(text);

  // Print the encoded text and its token length. 
  print(
    "Your text contains ${encoded.length} tokens, encoded as follows: $encoded",
  );

  // Decode back the encoded text token by token and print the results.
  encoded.forEach((token) {
    final decoded = GPT3Encoder.instance.decode([token]);
    print("Token: $token, decoded as: $decoded");
  });
}
```
