import 'dart:convert';
import 'dart:io';
import 'dart:math';

/// {@template gpt3_encoder}
/// This class can be used to encode/decode text for use with GPT models provided by OpenAI.
/// {@endtemplate}
class GPT3Encoder {
  /// {@macro gpt3_encoder}
  static GPT3Encoder _instance = GPT3Encoder._();

  /// {@macro gpt3_encoder}
  static GPT3Encoder get instance => _instance;

  final _decoder = {};
  Map<String, int>? _encoder;
  String? _bpeFile;
  List<String>? _lines;
  var _bpeMerges;
  Map<int, String>? _byteEncoder;
  Map? _byteDecoder;
  Map? _bpeRanks;
  Map? _cache;

  /// generates a new List of integers from x to y (exclusive)
  List<int> _range(int x, int y) {
    List<int> res = List<int>.generate(y, (index) => index);
    res = res.sublist(x);
    return res;
  }

  /// Splits a string into a list of characters
  List<String> _split(String str) {
    final _pat = RegExp(
      r'\s+',
      caseSensitive: false,
      multiLine: true,
      dotAll: true,
      unicode: true,
    );
    return str.split(_pat);
  }

  /// Returns the unicode code point of a character
  int _ord(String char) {
    return char.codeUnitAt(0);
  }

  /// Returns the character of a unicode code point
  String _chr(int x) {
    return String.fromCharCode(x);
  }

  /// The UTF-8 encoder.
  final _textEncoder = utf8;

  /// Encodes a string into a list of integers
  List<int> _encodeStr(String str) {
    final encoded = _textEncoder.encode(str);

    return encoded;
  }

  /// The UTF-8 decoder.
  final _textDecoder = utf8;

  /// Decodes a list of integers into a string
  String _decodeStr(List arr) {
    return _textDecoder.decode(
      arr.cast<int>(),
      allowMalformed: true,
    );
  }

  Map _dictZip(List<List<String>> x, List<int> y) {
    final result = {};
    x.asMap().forEach(
      (i, _) {
        final el = x[i].join('');
        final yel = y[i];
        result[el] = yel;
      },
    );

    return result;
  }

  Map<int, String> _bytesToUnicode() {
    final bs = _range(_ord('!'), _ord('~') + 1)
        .followedBy(_range(_ord('¡'), _ord('¬') + 1))
        .followedBy(_range(_ord('®'), _ord('ÿ') + 1))
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

    cs = cs.map((x) => _chr(x)).toList();
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

  final _pat = RegExp(
    r"'s|'t|'re|'ve|'m|'ll|'d| ?\p{L}+| ?\p{N}+| ?[^\s\p{L}\p{N}]+|\s+(?!\S)|\s+",
    unicode: true,
    dotAll: true,
  );
  String _bpe(String token) {
    if (_cache!.containsKey(token)) {
      return _cache![token];
    }
    dynamic word = token.split('');
    dynamic pairs = _getPairs(word);

    if (pairs == null || pairs.isEmpty) {
      return token;
    }

    bool isNaN(dynamic x) {
      return x == null || x.isNaN;
    }

    num _minimum(Iterable<num> nums) => nums.reduce(min);

    while (true) {
      final minPairs = {};
      final pairsList = List.from(pairs);
      pairsList.forEach((pair) {
        final rank = _bpeRanks![pair.join('')];
        minPairs[(isNaN(rank) ? 10e10 : rank)] = pair;
      });

      final minimum = _minimum(
        minPairs.keys.map(
          (x) {
            return x;
          },
        ),
      );

      final bigram = minPairs[minimum];

      if (!(_bpeRanks!.containsKey(bigram.join("")))) {
        break;
      }

      dynamic first = bigram[0];
      dynamic second = bigram[1];
      dynamic new_word = [];
      dynamic i = 0;

      while (i < word.length) {
        final j = word.indexOf(first, i);
        if (j == -1) {
          new_word = new_word.followedBy(word.sublist(i)).toList();
          break;
        }
        new_word = new_word.followedBy(word.sublist(i, j)).toList();
        i = j;

        if (word[i] == first && i < word.length - 1 && word[i + 1] == second) {
          new_word.add(first + second);
          i = i + 2;
        } else {
          new_word.add(word[i]);
          i = i + 1;
        }
      }

      word = new_word;
      if (word.length == 1) {
        break;
      } else {
        final wordList = (word as List).map((x) => x.toString()).toList();
        pairs = _getPairs(wordList);
      }
    }
    word = word.join(' ');
    _cache![token] = word;

    return word;
  }

  List<int> encode(String text) {
    List<int> bpe_tokens = [];
    final matches = _pat.allMatches(text).map((x) => x.group(0)).toList();
    for (var token in matches) {
      final encoded = _encodeStr(token!);
      final localToken = encoded.map((x) {
        final encoded = _byteEncoder![x];
        return encoded;
      }).join('');

      final new_tokens = _bpe(localToken)
          .split(' ')
          .map((x) => _encoder![x])
          .toList() as List<int?>;

      bpe_tokens = bpe_tokens.followedBy(new_tokens.cast()).toList();
    }

    return bpe_tokens;
  }

  String decode(List<int> tokens) {
    dynamic text = tokens.map((x) => _decoder[x]).join('');

    final splitted = text.split('');
    text = _decodeStr(splitted.map((x) {
      final encoded = _byteDecoder![x];
      return encoded as int;
    }).toList());
    return text;
  }

  GPT3Encoder._() {
    _encoder = (jsonDecode(File("./encoder.json").readAsStringSync())
            as Map<String, dynamic>)
        .cast<String, int>();

    _bpeFile = File("vocab.bpe").readAsStringSync();

    _encoder!.keys.forEach((e) {
      final encoded = _encoder![e];
      _decoder[encoded] = e;
    });

    _lines = _bpeFile!.split('\n');
    _bpeMerges = _lines!.sublist(1, _lines!.length - 1).map((x) {
      final splitted = x.split(RegExp(
        r'\s+',
        caseSensitive: false,
        multiLine: true,
        unicode: true,
      ));
      return splitted.where((e) => e.trim().isNotEmpty).toList();
    }).toList();

    _byteEncoder = _bytesToUnicode();
    _byteDecoder = {};
    _byteEncoder!.keys.forEach((x) => {_byteDecoder![_byteEncoder![x]] = x});
    _bpeRanks = _dictZip(_bpeMerges, _range(0, _bpeMerges.length));
    _cache = {};
  }
}
