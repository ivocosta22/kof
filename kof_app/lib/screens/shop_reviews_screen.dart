import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import '../models/shop.dart';

/// Reviews screen with mock data — placeholder until a real reviews backend
/// is wired up. Mock entries are deterministic per shop (seeded by shop id)
/// so the same shop always renders the same set of reviews.
class ShopReviewsScreen extends StatelessWidget {
  final Shop shop;
  const ShopReviewsScreen({super.key, required this.shop});

  static const _mock = <_MockReview>[
    _MockReview(
      author: 'Sara T.',
      rating: 5,
      daysAgo: 3,
      text:
          'Honestly the best flat white in town. The staff remembered my name on the second visit.',
    ),
    _MockReview(
      author: 'Daniel R.',
      rating: 4,
      daysAgo: 9,
      text:
          'Great vibe, the croissants are huge. Took off a star because the WiFi was a bit slow.',
    ),
    _MockReview(
      author: 'Lina M.',
      rating: 5,
      daysAgo: 14,
      text:
          'Quiet corner spot to work from. The cold brew is consistently excellent.',
    ),
    _MockReview(
      author: 'Marc P.',
      rating: 3,
      daysAgo: 21,
      text:
          'Coffee is solid but the pastries had run out by 11am on a weekday. Get there early.',
    ),
    _MockReview(
      author: 'Yuki K.',
      rating: 5,
      daysAgo: 32,
      text:
          'Lovely staff and the loyalty rewards through the app are a nice touch. Would recommend!',
    ),
  ];

  // Pull a deterministic slice + ordering of mock reviews using the shop id
  // as a hash seed, so two different shops feel different but each is stable.
  List<_MockReview> _reviewsForShop() {
    final seed = shop.id.hashCode;
    final rotated = [
      ..._mock.sublist(seed.abs() % _mock.length),
      ..._mock.sublist(0, seed.abs() % _mock.length),
    ];
    // Cap to a varied length per shop (3..5)
    final cap = 3 + (seed.abs() % 3);
    return rotated.take(cap).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final reviews = _reviewsForShop();
    final avg = reviews.isEmpty
        ? 0.0
        : reviews.fold<int>(0, (s, r) => s + r.rating) / reviews.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.shopReviewsHeading,
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: reviews.isEmpty
          ? Center(
              child: Text(
                l10n.shopReviewsEmpty,
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                _Summary(
                  averageRating: avg,
                  count: reviews.length,
                  l10n: l10n,
                  theme: theme,
                ),
                const SizedBox(height: 20),
                ...reviews.map((r) => _ReviewCard(review: r, theme: theme)),
              ],
            ),
    );
  }
}

class _MockReview {
  final String author;
  final int rating;
  final int daysAgo;
  final String text;
  const _MockReview({
    required this.author,
    required this.rating,
    required this.daysAgo,
    required this.text,
  });
}

class _Summary extends StatelessWidget {
  final double averageRating;
  final int count;
  final AppLocalizations l10n;
  final ThemeData theme;
  const _Summary({
    required this.averageRating,
    required this.count,
    required this.l10n,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                averageRating.toStringAsFixed(1),
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.primary,
                ),
              ),
              _StarRow(value: averageRating, size: 18),
            ],
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Text(
              l10n.shopReviewsBasedOn(count),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final _MockReview review;
  final ThemeData theme;
  const _ReviewCard({required this.review, required this.theme});

  String _ago(int days) {
    if (days < 1) return 'today';
    if (days < 7) return '${days}d ago';
    if (days < 30) return '${(days / 7).floor()}w ago';
    return '${(days / 30).floor()}mo ago';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor:
                    theme.colorScheme.primary.withValues(alpha: 0.15),
                child: Text(
                  review.author.isNotEmpty
                      ? review.author.characters.first
                      : '?',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.author,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      _ago(review.daysAgo),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              _StarRow(value: review.rating.toDouble(), size: 14),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            review.text,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  final double value;
  final double size;
  const _StarRow({required this.value, this.size = 14});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = value >= i + 1;
        final half = !filled && value > i + 0.25;
        return Icon(
          half
              ? Icons.star_half_rounded
              : (filled ? Icons.star_rounded : Icons.star_outline_rounded),
          size: size,
          color: Colors.amber.shade700,
        );
      }),
    );
  }
}
