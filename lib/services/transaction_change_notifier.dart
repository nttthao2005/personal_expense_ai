import 'package:flutter/foundation.dart';

class TransactionChangeNotifier extends ChangeNotifier {
  TransactionChangeNotifier._();

  static final TransactionChangeNotifier instance =
      TransactionChangeNotifier._();

  void notifyChanged() {
    notifyListeners();
  }
}
