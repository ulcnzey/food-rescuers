import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../controllers/consent_controller.dart';
import '../screens/legal_document_screen.dart';

class ConsentCheckbox extends ConsumerStatefulWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;

  const ConsentCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  ConsumerState<ConsentCheckbox> createState() => _ConsentCheckboxState();
}

class _ConsentCheckboxState extends ConsumerState<ConsentCheckbox> {
  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;
  bool _showHint = false;

  @override
  void initState() {
    super.initState();
    _termsRecognizer = TapGestureRecognizer()..onTap = _openTerms;
    _privacyRecognizer = TapGestureRecognizer()..onTap = _openPrivacy;
  }

  void _openTerms() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const LegalDocumentScreen(docType: 'terms'),
      ),
    );
  }

  void _openPrivacy() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const LegalDocumentScreen(docType: 'privacy'),
      ),
    );
  }

  void _handleRowTap() {
    final consent = ref.read(consentControllerProvider);
    if (!consent.hasReadAll) {
      setState(() => _showHint = true);
    }
  }

  @override
  void dispose() {
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final consent = ref.watch(consentControllerProvider);
    final hasReadAll = consent.hasReadAll;
    final termsRead = consent.isRead('terms');
    final privacyRead = consent.isRead('privacy');

    // Hide hint once both are read
    if (hasReadAll && _showHint) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _showHint = false);
      });
    }

    final linkStyle = TextStyle(
      color: AppColors.primary,
      fontWeight: FontWeight.bold,
      decoration: TextDecoration.underline,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: hasReadAll ? null : _handleRowTap,
          behavior: HitTestBehavior.translucent,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: widget.value,
                onChanged: hasReadAll ? widget.onChanged : null,
                activeColor: AppColors.primary,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Terms link + status icon
                      Row(
                        children: [
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: theme.textTheme.bodyMedium,
                                children: [
                                  TextSpan(
                                    text: 'Kullanım Koşulları',
                                    style: linkStyle,
                                    recognizer: _termsRecognizer,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: termsRead
                                ? const Icon(
                                    Icons.check_circle_rounded,
                                    key: ValueKey('terms_read'),
                                    color: AppColors.success,
                                    size: 18,
                                  )
                                : Icon(
                                    Icons.circle_outlined,
                                    key: const ValueKey('terms_unread'),
                                    color: theme.colorScheme.onSurfaceVariant,
                                    size: 18,
                                  ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      // Privacy link + status icon
                      Row(
                        children: [
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: theme.textTheme.bodyMedium,
                                children: [
                                  TextSpan(
                                    text: 'Gizlilik Politikası',
                                    style: linkStyle,
                                    recognizer: _privacyRecognizer,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: privacyRead
                                ? const Icon(
                                    Icons.check_circle_rounded,
                                    key: ValueKey('privacy_read'),
                                    color: AppColors.success,
                                    size: 18,
                                  )
                                : Icon(
                                    Icons.circle_outlined,
                                    key: const ValueKey('privacy_unread'),
                                    color: theme.colorScheme.onSurfaceVariant,
                                    size: 18,
                                  ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        "'nı okudum, kabul ediyorum.",
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Version info
        Padding(
          padding: const EdgeInsets.only(left: AppSpacing.xxl, top: 2.0),
          child: Text(
            'Sürüm 1 · 4 Ağustos 2026',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.brightness == Brightness.light
                  ? AppColors.textMutedLight
                  : AppColors.textMutedDark,
              fontSize: 11,
            ),
          ),
        ),
        // Inline hint when user tries to tick without reading
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.topLeft,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: _showHint && !hasReadAll ? 1.0 : 0.0,
            child: _showHint && !hasReadAll
                ? Padding(
                    padding: const EdgeInsets.only(
                        left: AppSpacing.xxl, top: AppSpacing.xs),
                    child: Text(
                      'Önce her iki belgeyi de okumanız gerekiyor.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),
        // Confirmation line when both are read
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.topLeft,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: hasReadAll ? 1.0 : 0.0,
            child: hasReadAll
                ? Padding(
                    padding: const EdgeInsets.only(
                        left: AppSpacing.xxl, top: AppSpacing.xs),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            color: AppColors.success, size: 14),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'Her iki belge de okundu.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}
