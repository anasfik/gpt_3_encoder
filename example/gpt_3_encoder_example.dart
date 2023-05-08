import 'package:gpt_3_encoder/gpt_3_encoder.dart';

void main() {
  // This is the text we want to encode and decode.
  final text = "Hello World!";

  // Encode the text.
  final encoded = GPT3Encoder.instance.encode(text);

  // Print the encoded text.
  print(
    "Your text contains ${encoded.length} tokens, encoded as follows: $encoded",
  );

  // Decode the encoded text token by token and print the result.
  for (var token in encoded) {
    final decoded = GPT3Encoder.instance.decode([token]);
    print("Token: $token, decoded as: $decoded");
  }
}
