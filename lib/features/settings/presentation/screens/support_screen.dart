import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/illustrations/app_illustrations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../controllers/settings_controller.dart';

enum SupportType { contact, bug, suggestion }

extension SupportTypeX on SupportType {
  String get dbValue => switch (this) {
        SupportType.contact => 'contact',
        SupportType.bug => 'bug',
        SupportType.suggestion => 'suggestion',
      };

  String get title => switch (this) {
        SupportType.contact => 'İletişim',
        SupportType.bug => 'Sorun Bildir',
        SupportType.suggestion => 'Öneri Gönder',
      };

  String get hint => switch (this) {
        SupportType.contact =>
          'Sorunuzu veya mesajınızı buraya yazabilirsiniz...',
        SupportType.bug =>
          'Karşılaştığın sorunu adım adım anlat. Hangi ekranda oldu?',
        SupportType.suggestion =>
          'Uygulamada görmek istediğin özelliği anlat...',
      };

  IconData get icon => switch (this) {
        SupportType.contact => Icons.mail_outline_rounded,
        SupportType.bug => Icons.bug_report_outlined,
        SupportType.suggestion => Icons.lightbulb_outline_rounded,
      };
}

class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key, this.initialType = SupportType.contact});

  final SupportType initialType;

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  final _emailController = TextEditingController();

  late SupportType _type = widget.initialType;
  String? _error;
  bool _sent = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _subjectController.text.trim().length >= 3 &&
      _messageController.text.trim().length >= 10;

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _error = null);

    final error =
        await ref.read(settingsControllerProvider.notifier).submitTicket(
              type: _type.dbValue,
              subject: _subjectController.text,
              message: _messageController.text,
              email: _emailController.text.trim().isEmpty
                  ? null
                  : _emailController.text,
            );

    if (!mounted) return;

    if (error != null) {
      setState(() => _error = error);
      return;
    }

    setState(() => _sent = true);
    await Future<void>.delayed(const Duration(milliseconds: 1800));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLoading = ref.watch(settingsControllerProvider);

    if (_sent) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 160,
                  height: 160,
                  child: SuccessIllustration(size: 160),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('Mesajın alındı', style: theme.textTheme.headlineSmall),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'En kısa sürede dönüş yapacağız. Teşekkürler!',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(_type.title)),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              // ---- Tur secimi
              Row(
                children: SupportType.values.map((t) {
                  final active = t == _type;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: GestureDetector(
                        onTap: () => setState(() => _type = t),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: active
                                ? AppColors.primary.withValues(alpha: 0.10)
                                : theme.colorScheme.surface,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusLg),
                            border: Border.all(
                              color: active
                                  ? AppColors.primary
                                  : theme.colorScheme.outline,
                              width: active ? 1.6 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                t.icon,
                                size: 22,
                                color: active
                                    ? AppColors.primary
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(height: 5),
                              Text(
                                t.title,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: active
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: AppSpacing.xl),

              const _Label('Konu'),
              TextField(
                controller: _subjectController,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                maxLength: 80,
                decoration: const InputDecoration(
                  hintText: 'Kısa bir başlık yaz',
                  counterText: '',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.lg),

              const _Label('Mesajın'),
              TextField(
                controller: _messageController,
                maxLines: 6,
                maxLength: 1000,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(hintText: _type.hint),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.sm),

              const _Label('E-posta (isteğe bağlı)'),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'Farklı bir adresten dönüş isterseniz',
                  prefixIcon: Icon(Icons.alternate_email_rounded),
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: AppColors.error,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          _error!,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(top: BorderSide(color: theme.colorScheme.outline)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: (!_canSubmit || isLoading) ? null : _submit,
              child: isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Gönder'),
            ),
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .labelLarge
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}