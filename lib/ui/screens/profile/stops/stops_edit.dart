import 'package:busin/controllers/bus_stops_controller.dart';
import 'package:busin/models/value_objects/bus_stop_selection.dart';
import 'package:busin/ui/components/widgets/default_snack_bar.dart';
import 'package:busin/ui/components/widgets/form_fields/select_image.dart';
import 'package:busin/ui/components/widgets/form_fields/simple_text_field.dart';
import 'package:busin/ui/components/widgets/buttons/primary_button.dart';
import 'package:busin/utils/constants.dart';
import 'package:busin/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

class EditStopPage extends StatefulWidget {
  final String stopId;

  const EditStopPage({super.key, required this.stopId});

  static const String routeName = '/edit-stop';

  @override
  State<EditStopPage> createState() => _EditStopPageState();
}

class _EditStopPageState extends State<EditStopPage> {
  // Form
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Text controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mapEmbedController = TextEditingController();

  // GetX Controllers
  final BusStopsController _busStopsController = Get.find<BusStopsController>();

  // Form fields
  String? _pickupImageUrl;
  bool _isSubmitting = false;
  bool _isLoading = true;
  BusStop? _currentStop;

  @override
  void initState() {
    super.initState();
    _loadStopData();
  }

  Future<void> _loadStopData() async {
    setState(() => _isLoading = true);

    // Try to get from controller first
    _currentStop = _busStopsController.getBusStopById(widget.stopId);

    // If not found in controller, fetch from service
    if (_currentStop == null) {
      await _busStopsController.fetchBusStops();
      _currentStop = _busStopsController.getBusStopById(widget.stopId);
    }

    if (_currentStop != null) {
      // Prefill form fields
      _nameController.text = _currentStop!.name;
      _mapEmbedController.text = _currentStop!.mapEmbedUrl ?? '';
      _pickupImageUrl = _currentStop!.pickupImageUrl;
    }

    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mapEmbedController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_currentStop == null) return;

    setState(() => _isSubmitting = true);

    final name = _nameController.text.trim();
    final mapUrl = _mapEmbedController.text.trim();

    // Create updated stop
    final updatedStop = _currentStop!.copyWith(
      name: name,
      pickupImageUrl: _pickupImageUrl,
      mapEmbedUrl: mapUrl.isEmpty ? null : mapUrl,
    );

    final success = await _busStopsController.updateBusStop(updatedStop);

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    if (success) {
      context.pop();
      ScaffoldMessenger.of(context)..hideCurrentSnackBar()..showSnackBar(
        buildSnackBar(
          prefixIcon: const Icon(Icons.check_circle, color: lightColor),
          label: const Text('Bus stop updated successfully'),
          backgroundColor: successColor,
        ),
      );
    } else {
      ScaffoldMessenger.of(context)..hideCurrentSnackBar()..showSnackBar(
        buildSnackBar(
          prefixIcon: const Icon(Icons.error, color: lightColor),
          label: Text(
            _busStopsController.error.value.isNotEmpty
                ? _busStopsController.error.value
                : 'Failed to update bus stop',
          ),
          backgroundColor: errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Bus Stop')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentStop == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Bus Stop')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const HugeIcon(icon: HugeIcons.strokeRoundedAlert02, size: 64.0),
              const Gap(16.0),
              Text('Bus stop not found', style: AppTextStyles.h3),
              const Gap(24.0),
              PrimaryButton.label(
                onPressed: () => context.pop(),
                label: 'Go Back',
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Edit Bus Stop')),
        body: Form(
          key: _formKey,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(16.0).copyWith(bottom: 80.0),
            children: [
              Image.asset(busStop, height: 200.0),
              const Gap(16.0),
              Container(
                padding: EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: infoColor.withValues(alpha: 0.1),
                  borderRadius: borderRadius * 2.5,
                ),
                child: Row(
                  spacing: 8.0,
                  children: [
                    HugeIcon(icon: infoIcon, color: infoColor),
                    Expanded(
                      child: Text(
                        'Update the information for this bus stop. Changes will be reflected for all users who have subscribed to this stop.',
                        style: AppTextStyles.body.copyWith(color: infoColor),
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(24.0),
              Text('Bus Stop Details', style: AppTextStyles.h2),
              const Gap(16.0),
              ImageBox(
                initialImageUrl: _currentStop!.pickupImageUrl,
                onImageSelected: (filePath) {
                  setState(() {
                    _pickupImageUrl = filePath;
                  });
                },
                label: "Upload a capture of the place (optional)",
              ),
              const Gap(16.0),
              SimpleTextFormField(
                controller: _nameController,
                hintText: "Name of the place",
                label: const Text("Pickup place name *"),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter the name of the bus stop';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.words,
                keyboardType: TextInputType.text,
              ),
              const Gap(16.0),
              SimpleTextFormField(
                controller: _mapEmbedController,
                hintText: "A Google maps link to the place",
                label: const Text("Maps URL (optional)"),
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    final urlPattern = RegExp(
                      r'^https?:\/\/(www\.)?(google\.com\/maps|maps\.google\.com|maps\.app\.goo\.gl|goo\.gl)',
                      caseSensitive: false,
                    );
                    if (!urlPattern.hasMatch(value.trim())) {
                      return 'Please enter a valid Google Maps link';
                    }
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.none,
                keyboardType: TextInputType.url,
              ),
              const Gap(24.0),
              Container(
                padding: EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: warningColor.withValues(alpha: 0.1),
                  borderRadius: borderRadius * 2,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Metadata',
                      style: AppTextStyles.small.copyWith(
                        fontWeight: FontWeight.bold,
                        color: warningColor,
                      ),
                    ),
                    const Gap(8.0),
                    Row(
                      children: [
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedCalendar03,
                          color: warningColor,
                          size: 16.0,
                        ),
                        const Gap(8.0),
                        Expanded(
                          child: Text(
                            'Created: ${dateTimeFormatter(_currentStop!.createdAt)}',
                            style: AppTextStyles.small.copyWith(
                              color: warningColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Gap(4.0),
                    Row(
                      children: [
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedCalendar03,
                          color: warningColor,
                          size: 16.0,
                        ),
                        const Gap(8.0),
                        Expanded(
                          child: Text(
                            'Last updated: ${dateTimeFormatter(_currentStop!.updatedAt)}',
                            style: AppTextStyles.small.copyWith(
                              color: warningColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_currentStop!.updatedBy.isNotEmpty) ...[
                      const Gap(4.0),
                      Row(
                        children: [
                          const HugeIcon(
                            icon: HugeIcons.strokeRoundedUserEdit01,
                            size: 16.0,
                          ),
                          const Gap(8.0),
                          Expanded(
                            child: Text(
                              'Updated by: ${_currentStop!.updatedBy.length} user(s)',
                              style: AppTextStyles.small,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const Gap(16.0),
              Obx(
                () => PrimaryButton.label(
                  onPressed:
                      _isSubmitting || _busStopsController.isLoading.value
                      ? null
                      : _handleSubmit,
                  label: _isSubmitting || _busStopsController.isLoading.value
                      ? "Updating..."
                      : "Update stop",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
