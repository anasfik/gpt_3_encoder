// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import 'dart:io';

import 'package:gpt_3_encoder/src/core/utils.dart';

/// {@template gpt3_encoder_bpe}
/// This class will be responsible to manage and handle the bpe encoding for the [GPT3Encoder].
/// {@endtemplate}
class GPT3EncoderBpe {
  Map? bpeRanks;
  Map? cache;
  var bpeMerges;
  List<String>? lines;
  Map<String, int>? encoder;
  String? bpeFile;
  final decoder = {};

  /// {@macro gpt3_encoder_bpe}
  GPT3EncoderBpe() {
    cache = {};

    bpeFile = File("vocab.bpe").readAsStringSync();

    lines = bpeFile!.split('\n');

    bpeMerges = lines!.sublist(1, lines!.length - 1).map((x) {
      final splitted = x.split(RegExp(
        r'\s+',
        caseSensitive: false,
        multiLine: true,
        unicode: true,
      ));
      return splitted.where((e) => e.trim().isNotEmpty).toList();
    }).toList();

    bpeRanks = GPT3EncoderUtils.dictZip(
      bpeMerges,
      GPT3EncoderUtils.range(0, bpeMerges.length),
    );

    encoder = (jsonDecode(File("./encoder.json").readAsStringSync())
            as Map<String, dynamic>)
        .cast<String, int>();

    for (var e in encoder!.keys) {
      final encoded = encoder![e];
      decoder[encoded] = e;
    }
  }

  Set<List<String>> _getPairs(List<String> word) {
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
      return cache![token];
    }
    dynamic word = token.split('');
    dynamic pairs = _getPairs(word);

    if (pairs == null || pairs.isEmpty) {
      return token;
    }

    while (true) {
      final minPairs = {};
      final pairsList = List.from(pairs);
      for (var pair in pairsList) {
        final rank = bpeRanks![pair.join('')];
        minPairs[(GPT3EncoderUtils.isNaN(rank) ? 10e10 : rank)] = pair;
      }

      final minimum = GPT3EncoderUtils.minimum(
        minPairs.keys.map(
          (x) {
            return x;
          },
        ),
      );

      final bigram = minPairs[minimum];

      if (!(bpeRanks!.containsKey(bigram.join("")))) {
        break;
      }

      dynamic first = bigram[0];
      dynamic second = bigram[1];
      dynamic newWord = [];
      dynamic i = 0;

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
        final wordList = (word as List).map((x) => x.toString()).toList();
        pairs = _getPairs(wordList);
      }
    }
    word = word.join(' ');
    cache![token] = word;

    return word;
  }
}
