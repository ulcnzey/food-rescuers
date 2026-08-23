import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';

/// Basit markdown gorunumu. Paket eklemek yerine "## " ile
/// baslayan satirlari baslik, digerlerini paragraf olarak isliyoruz.
/// Yasal metinler icin bu kadari yeterli; bagimlilik eklemedik.
class MarkdownText extends StatelessWidget {
  const MarkdownText({super.key, required this.content});

  final String content;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lines = content.split('\n');
    final widgets = <Widget>[];

    for (final raw in lines) {
      final line = raw.trim();

      if (line.isEmpty) {
        widgets.add(const SizedBox(height: AppSpacing.sm));
        continue;
      }

      if (line.startsWith('## ')) {
        widgets
          ..add(const SizedBox(height: AppSpacing.md))
          ..add(
            Text(
              line.substring(3),
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
          )
          ..add(const SizedBox(height: AppSpacing.xs));
        continue;
      }

      if (line.startsWith('- ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('•  ', style: theme.textTheme.bodyMedium),
                Expanded(
                  child: Text(
                    line.substring(2),
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                  ),
                ),
              ],
            ),
          ),
        );
        continue;
      }

      widgets.add(
        Text(
          line,
          style: theme.textTheme.bodyMedium?.copyWith(height: 1.65),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }
}