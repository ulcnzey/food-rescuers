import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/mock_legal_repository.dart';
import '../../domain/entities/legal_document.dart';
import '../controllers/consent_controller.dart';

class LegalDocumentScreen extends ConsumerStatefulWidget {
  final String docType;

  const LegalDocumentScreen({super.key, required this.docType});

  @override
  ConsumerState<LegalDocumentScreen> createState() =>
      _LegalDocumentScreenState();
}

class _LegalDocumentScreenState extends ConsumerState<LegalDocumentScreen> {
  final ScrollController _scrollController = ScrollController();
  final LegalRepository _repository = MockLegalRepository();

  LegalDocument? _document;
  bool _isLoading = true;
  String? _errorMessage;
  double _scrollProgress = 0.0;

  bool _hasReachedEnd = false;
  bool _minimumTimeElapsed = false;
  Timer? _minimumTimer;

  bool get _canMarkAsRead => _hasReachedEnd && _minimumTimeElapsed;

  @override
  void initState() {
    super.initState();
    _loadDocument();
    _scrollController.addListener(_onScroll);

    // Start 3-second minimum timer
    _minimumTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _minimumTimeElapsed = true);
      }
    });
  }

  Future<void> _loadDocument() async {
    try {
      final doc = await _repository.getDocument(widget.docType);
      if (mounted) {
        setState(() {
          _document = doc;
          _isLoading = false;
        });
        // After loading, check if content fits within viewport (nothing to scroll)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _checkContentFitsViewport();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Belge yüklenirken bir hata oluştu.';
          _isLoading = false;
        });
      }
    }
  }

  void _checkContentFitsViewport() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    if (maxScroll <= 0) {
      // Content fits entirely within the viewport — no scroll needed
      setState(() => _hasReachedEnd = true);
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    if (maxScroll <= 0) {
      setState(() {
        _scrollProgress = 1.0;
        _hasReachedEnd = true;
      });
      return;
    }
    final currentScroll = _scrollController.position.pixels;
    final progress = (currentScroll / maxScroll).clamp(0.0, 1.0);
    setState(() {
      _scrollProgress = progress;
      if (maxScroll - currentScroll <= 40) {
        _hasReachedEnd = true;
      }
    });
  }

  void _handleConfirm() {
    ref.read(consentControllerProvider.notifier).markAsRead(widget.docType);
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _minimumTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  List<Widget> _parseContent(String content, ThemeData theme) {
    final List<Widget> widgets = [];
    final lines = content.split('\n');

    for (var line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        widgets.add(const SizedBox(height: AppSpacing.md));
        continue;
      }

      if (trimmed.startsWith('## ')) {
        final headingText = trimmed.substring(3).trim();
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(
                top: AppSpacing.lg, bottom: AppSpacing.sm),
            child: Text(
              headingText,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
                letterSpacing: -0.5,
              ),
            ),
          ),
        );
      } else {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              trimmed,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.6,
                color: theme.brightness == Brightness.light
                    ? AppColors.textLight.withValues(alpha: 0.85)
                    : AppColors.textDark.withValues(alpha: 0.85),
              ),
            ),
          ),
        );
      }
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_document?.title ?? 'Belge Yükleniyor...'),
        actions: [
          if (_document != null)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Text(
                    'Sürüm ${_document!.version}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: SizedBox(
            height: 4.0,
            width: double.infinity,
            child: LinearProgressIndicator(
              value: _scrollProgress,
              backgroundColor:
                  theme.colorScheme.outline.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primary),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(child: Text(_errorMessage!))
                : Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.md,
                          ),
                          child: Center(
                            child: ConstrainedBox(
                              constraints:
                                  const BoxConstraints(maxWidth: 600),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: _parseContent(
                                    _document!.content, theme),
                              ),
                            ),
                          ),
                        ),
                      ),
                      _BottomBar(
                        canConfirm: _canMarkAsRead,
                        scrollProgress: _scrollProgress,
                        hasReachedEnd: _hasReachedEnd,
                        onConfirm: _handleConfirm,
                      ),
                    ],
                  ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final bool canConfirm;
  final double scrollProgress;
  final bool hasReachedEnd;
  final VoidCallback onConfirm;

  const _BottomBar({
    required this.canConfirm,
    required this.scrollProgress,
    required this.hasReachedEnd,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    String label;
    if (canConfirm) {
      label = 'Okudum ve Anladım';
    } else if (hasReachedEnd) {
      // Reached end but timer hasn't elapsed
      label = 'Lütfen belgeyi sonuna kadar okuyun';
    } else if (scrollProgress > 0) {
      final pct = (scrollProgress * 100).round();
      label = 'Okundu: %$pct';
    } else {
      label = 'Lütfen belgeyi sonuna kadar okuyun';
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outline),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: FilledButton.icon(
              key: ValueKey(canConfirm),
              onPressed: canConfirm ? onConfirm : null,
              icon: AnimatedScale(
                scale: canConfirm ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: canConfirm
                    ? const Icon(Icons.check_rounded, size: 20)
                    : const SizedBox.shrink(),
              ),
              label: Text(label),
            ),
          ),
        ),
      ),
    );
  }
}
