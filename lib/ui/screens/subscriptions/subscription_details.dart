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
    return GetBuilder<BusSubscriptionsController>(
      builder: (busSubscriptionsController) {
        final BusSubscription busSubscription =
            busSubscriptionsController.getSubscriptionById(subscriptionId);
        return Scaffold(
          appBar: AppBar(
            title: Text("Subscription Details"),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(busSubscription),
                const SizedBox(height: 16.0),
                _buildScheduleSection(context, busSubscription),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BusSubscription subscription) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.blueAccent,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subscription.semesterYear,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            subscription.status.label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleSection(BuildContext context, BusSubscription subscription) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Weekly Schedule",
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8.0),
          ...subscription.schedules.map(
            (schedule) => _buildScheduleTile(context, schedule),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildScheduleTile(BuildContext context, BusSubscriptionSchedule schedule) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        title: Text("Day: ${weekdays(context)[schedule.weekday]}"),
        subtitle: Text(
          "Morning: ${schedule.morningTime} - Closing: ${schedule.closingTime}",
        ),
      ),
    );
  }
}
