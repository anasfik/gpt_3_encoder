import 'package:gpt_3_encoder/gpt_3_encoder.dart';
import 'package:test/test.dart';

void main() {
  List<int>? encoded;

  test("encoding a text", () {
    final text = "This is a test";
    encoded = GPT3Encoder.instance.encode(text);
    expect(encoded, isNotNull);
    expect(encoded!.length, equals(4));
    expect(encoded![0], 1212);
    expect(encoded![1], 318);
    expect(encoded![2], 257);
    expect(encoded![3], 1332);
  });

  test("decoding the encoded text", () {
    expect(GPT3Encoder.instance.decode(encoded!), isNotNull);
    expect(GPT3Encoder.instance.decode(encoded!), equals("This is a test"));
    expect(GPT3Encoder.instance.decode([encoded![0]]), equals("This"));
    expect(GPT3Encoder.instance.decode([encoded![1]]), equals(" is"));
    expect(GPT3Encoder.instance.decode([encoded![2]]), equals(" a"));
    expect(GPT3Encoder.instance.decode([encoded![3]]), equals(" test"));
  });
}
