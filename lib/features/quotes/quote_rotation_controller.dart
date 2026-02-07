import 'package:flutter/foundation.dart';

import 'quotes.dart';

typedef QuoteIndexGenerator = int Function(int maxExclusive);

class QuoteRotationController extends ChangeNotifier {
  QuoteRotationController({
    List<String>? quotes,
    QuoteIndexGenerator? nextIndex,
    int initialIndex = 0,
  })  : _quotes = List<String>.unmodifiable(quotes ?? mindfulQuotes),
        _nextIndex = nextIndex,
        _currentIndex = normalizedQuoteIndex(
          initialIndex,
          (quotes ?? mindfulQuotes).length,
        );

  final List<String> _quotes;
  final QuoteIndexGenerator? _nextIndex;
  int _currentIndex;

  int get currentIndex => _currentIndex;
  String get currentQuote => _quotes.isEmpty ? '' : _quotes[_currentIndex];
  bool get hasQuotes => _quotes.isNotEmpty;

  void rotate({String? reason}) {
    if (_quotes.isEmpty) {
      return;
    }
    int nextIndex;
    if (_nextIndex != null) {
      nextIndex = normalizedQuoteIndex(_nextIndex!(_quotes.length), _quotes.length);
    } else {
      nextIndex = (_currentIndex + 1) % _quotes.length;
    }
    if (nextIndex == _currentIndex) {
      return;
    }
    _currentIndex = nextIndex;
    notifyListeners();
  }
}
