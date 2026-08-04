import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConsentState {
  final Set<String> readDocTypes;

  const ConsentState({this.readDocTypes = const {}});

  bool get hasReadAll => readDocTypes.containsAll({'terms', 'privacy'});

  bool isRead(String docType) => readDocTypes.contains(docType);

  ConsentState markRead(String docType) {
    return ConsentState(readDocTypes: {...readDocTypes, docType});
  }
}

class ConsentController extends StateNotifier<ConsentState> {
  ConsentController() : super(const ConsentState());

  void markAsRead(String docType) {
    state = state.markRead(docType);
  }

  void reset() {
    state = const ConsentState();
  }
}

final consentControllerProvider =
    StateNotifierProvider<ConsentController, ConsentState>(
  (ref) => ConsentController(),
);
