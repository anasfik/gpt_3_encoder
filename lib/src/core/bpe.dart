// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import 'dart:io';

import 'package:gpt_3_encoder/src/core/utils.dart';

/// {@template gpt3_encoder_bpe}
/// This class will be responsible to manage and handle the bpe encoding for the [GPT3Encoder].
/// {@endtemplate}
class GPT3EncoderBpe {
  Map<String, int>? bpeRanks;
  Map<String, String>? cache;
  List<List<String>>? bpeMerges;
  List<String>? lines;
  Map<String, int>? encoder;
  String? bpeFile;
  Map<int?, String>? decoder;

  /// {@macro gpt3_encoder_bpe}
  GPT3EncoderBpe() {
    cache = {};
    decoder = {};
    bpeFile = File("vocab.bpe").readAsStringSync();
    lines = bpeFile!.split('\n');
    bpeMerges = _mergesFromBpeFile();
    bpeRanks = _dictZip(
      bpeMerges!,
      GPT3EncoderUtils.range(0, bpeMerges!.length),
    );
    encoder = _encoderDataFromEncoderFile();
    for (String e in encoder!.keys) {
      final encoded = encoder![e];
      decoder![encoded] = e;
    }
  }

  Set<List<String>>? _getPairs(List<String> word) {
    final pairs = <List<String>>{};

    String prevChar = word[0];
    for (int i = 1; i < word.length; i++) {
      final char = word[i];
      pairs.add([prevChar, char]);
      prevChar = char;
    }

    return pairs;
  }

  String call(String token) {
    if (cache!.containsKey(token)) {
      return cache![token]!;
    }
    List<String> word = token.split('');
    Set<List<String>>? pairs = _getPairs(word);

    if (pairs == null || pairs.isEmpty) {
      return token;
    }

    while (true) {
      final minPairs = {};
      final pairsList = List.of(pairs!);
      for (List<String> pair in pairsList) {
        final rank = bpeRanks![pair.join('')];
        minPairs[(GPT3EncoderUtils.isNaN(rank) ? 10e10 : rank)] = pair;
      }

      final minimum = GPT3EncoderUtils.minimum(minPairs.keys.map((x) => x));

      final bigram = minPairs[minimum];

      final doesNotContain = !(bpeRanks!.containsKey(bigram.join("")));
      if (doesNotContain) {
        break;
      }

      String first = bigram[0];
      String second = bigram[1];
      List<String> newWord = [];
      int i = 0;

      while (i < word.length) {
        final j = word.indexOf(first, i);
        if (j == -1) {
          newWord = newWord.followedBy(word.sublist(i)).toList();
          break;
        }
        newWord = newWord.followedBy(word.sublist(i, j)).toList();
        i = j;

        if (word[i] == first && i < word.length - 1 && word[i + 1] == second) {
          newWord.add(first + second);
          i = i + 2;
        } else {
          newWord.add(word[i]);
          i = i + 1;
        }
      }

      word = newWord;
      if (word.length == 1) {
        break;
      } else {
        final wordList = word.map((x) => x.toString()).toList();
        pairs = _getPairs(wordList);
      }
    }

    final finalWordResult = word.join(' ');
    cache![token] = finalWordResult;

    return finalWordResult;
  }

  List<List<String>>? _mergesFromBpeFile() {
    final sublist = lines!.sublist(1, lines!.length - 1);
    final emptySpacesRegExp = RegExp(
      r'\s+',
      caseSensitive: false,
      multiLine: true,
      unicode: true,
    );

    return sublist.map((x) {
      final splatter = x.split(emptySpacesRegExp);
      return splatter.where((e) => e.trim().isNotEmpty).toList();
    }).toList();
  }

  static Map<String, int> _dictZip(List<List<String>> x, List<int> y) {
    final result = <String, int>{};

    x.asMap().forEach(
      (i, _) {
        final el = x[i].join('');
        final yel = y[i];
        result[el] = yel;
      },
    );

    return result;
  }

  Map<String, int> _encoderDataFromEncoderFile() {
    return (jsonDecode(File("./encoder.json").readAsStringSync())
            as Map<String, dynamic>)
        .cast<String, int>();
  }
}
