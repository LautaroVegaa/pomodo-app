const List<String> mindfulQuotes = <String>[
  'Every time you switch apps, your focus pays the price.',
  'Short videos train your brain to quit early.',
  'Distraction feels good now. Progress feels good later.',
  'If it’s free, your attention is the product.',
  'Your brain didn’t evolve for endless scrolling.',
  'Silence is where clarity lives.',
  'You don’t need more content. You need more presence.',
  'Put the phone down. Pick yourself up.',
  'Being bored is the first step to being creative.',
  'Nothing important happens in the next swipe.',
  'Small focus sessions build big outcomes.',
  'You don’t need motivation. You need a system.',
  'Progress is quiet. Distraction is loud.',
  'Focus today. Momentum tomorrow.',
  'What you do daily matters more than what you plan once.',
  'Your future self is watching this moment.',
  'Consistency beats intensity.',
  'Deep work compounds. Scrolling doesn’t.',
  'Protect your attention like you protect your time.',
  'This is not about productivity. It’s about direction.',
];

int normalizedQuoteIndex(int index, int quoteCount) {
  if (quoteCount <= 0) {
    return 0;
  }
  final int normalized = index % quoteCount;
  return normalized >= 0 ? normalized : quoteCount + normalized;
}

String quoteForIndex(int index, {List<String>? source}) {
  final List<String> quotes = source ?? mindfulQuotes;
  if (quotes.isEmpty) {
    return '';
  }
  final int normalized = normalizedQuoteIndex(index, quotes.length);
  return quotes[normalized];
}
