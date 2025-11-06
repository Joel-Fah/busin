import 'package:busin/models/subscription.dart';
import 'package:get/get.dart';

class BusSubscriptionsController extends GetxController {
  RxList<BusSubscription> _busSubscriptions = dummySubscriptions.obs;

  List<BusSubscription> get busSubscriptions => _busSubscriptions;

  // Firebase collection
  static const String kSubscriptionsCollection = 'subscriptions';

  // Public methods

  // Get subscription by ID from Firebase
  BusSubscription getSubscriptionById(String id) {
    return _busSubscriptions.firstWhere((sub) => sub.id == id);
  }
}