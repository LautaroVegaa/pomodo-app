import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../app/quote_scope.dart';
import 'flow_focus_shell.dart';

class QuoteBlock extends StatelessWidget {
  const QuoteBlock({super.key});

  @override
  Widget build(BuildContext context) {
    if (FlowFocusScope.of(context)) {
      return const SizedBox.shrink();
    }
    final quoteController = QuoteScope.of(context);
    return AnimatedBuilder(
      animation: quoteController,
      builder: (context, _) {
        final String quote = quoteController.currentQuote;
        if (quote.isEmpty) {
          return const SizedBox.shrink();
        }
        return _QuoteCard(quote: quote);
      },
    );
  }
}

class _QuoteCard extends StatelessWidget {
  const _QuoteCard({required this.quote});

  final String quote;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.auto_awesome_rounded,
            color: Colors.white70,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              quote,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textPrimary.withValues(alpha: 0.8),
                    height: 1.4,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
