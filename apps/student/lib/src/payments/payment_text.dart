import 'package:busin_core/busin_core.dart';
import 'package:busin_ui/busin_ui.dart';

/// The student's own words for why a payment did not go through. pawaPay's message is for BusIn's team, never shown.
String failureText(BusinL10n l10n, PaymentFailure failure) => switch (failure) {
  PaymentFailure.notApproved => l10n.payFailNotApproved,
  PaymentFailure.insufficientBalance => l10n.payFailBalance,
  PaymentFailure.payerNotFound => l10n.payFailNotFound,
  PaymentFailure.limitReached => l10n.payFailLimit,
  PaymentFailure.otherPending => l10n.payFailOtherPending,
  PaymentFailure.operatorDown => l10n.payFailOperatorDown,
  PaymentFailure.amountOutOfBounds => l10n.payFailAmount,
  PaymentFailure.invalidNumber => l10n.payFailNumber,
  PaymentFailure.notReached || PaymentFailure.other => l10n.payFailGeneric,
};

/// Why a payment could not even start, from the server's short code.
String refusalText(BusinL10n l10n, Object error) => switch (error) {
  Offline() => l10n.errorOffline,
  RepositoryException(reason: 'payment_in_progress') => l10n.payErrorInProgress,
  RepositoryException(reason: 'too_many_attempts') => l10n.payErrorTooMany,
  RepositoryException(reason: 'not_payable' || 'period_ended') => l10n.payErrorNotPayable,
  RepositoryException(reason: 'bad_phone' || 'unknown_provider') => l10n.payPhoneInvalid,
  RepositoryException(reason: 'payments_unavailable' || 'mobile_money_off' || 'fees_not_set') => l10n.payErrorUnavailable,
  _ => l10n.payFailGeneric,
};

/// The operator's name as students know it.
String operatorName(MobileMoneyOperator operator) => switch (operator) {
  MobileMoneyOperator.mtn => 'MTN Mobile Money',
  MobileMoneyOperator.orange => 'Orange Money',
};
