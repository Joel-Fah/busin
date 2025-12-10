import 'package:busin/controllers/controllers.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../models/subscription.dart';
import '../../../utils/constants.dart';
import '../../../utils/utils.dart';

class SubscriptionDetailsPage extends StatelessWidget {
  static const String routeName = '/subscription-details';

  final String subscriptionId;

  const SubscriptionDetailsPage({Key? key, required this.subscriptionId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }
}
