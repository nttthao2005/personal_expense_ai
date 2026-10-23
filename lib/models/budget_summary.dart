import 'budget.dart';

class BudgetSummary {
  final Budget budget;
  final double spent;

  const BudgetSummary({required this.budget, required this.spent});

  double get remaining => budget.amount - spent;

  double get usageRatio {
    if (budget.amount <= 0) {
      return 0;
    }

    return spent / budget.amount;
  }

  bool get isOverBudget => spent > budget.amount;
}
