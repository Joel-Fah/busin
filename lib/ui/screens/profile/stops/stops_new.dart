import 'package:busin/controllers/bus_stops_controller.dart';
import 'package:busin/ui/components/widgets/default_snack_bar.dart';
import 'package:busin/ui/components/widgets/form_fields/select_image.dart';
import 'package:busin/ui/components/widgets/form_fields/simple_text_field.dart';
import 'package:busin/ui/components/widgets/primary_button.dart';
import 'package:busin/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

class NewStopPage extends StatefulWidget {
  const NewStopPage({super.key});

  static const String routeName = '/new-stop';

  @override
  State<NewStopPage> createState() => _NewStopPageState();
}

class _NewStopPageState extends State<NewStopPage> {
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

  @override
  void dispose() {
    _nameController.dispose();
    _mapEmbedController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final name = _nameController.text.trim();
    final mapUrl = _mapEmbedController.text.trim();

    final createdStop = await _busStopsController.createBusStop(
      name: name,
      pickupImageUrl: _pickupImageUrl,
      mapEmbedUrl: mapUrl.isEmpty ? null : mapUrl,
    );

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    if (createdStop != null) {
      context.pop();
      ScaffoldMessenger.of(context)..hideCurrentSnackBar()..showSnackBar(
        buildSnackBar(
          prefixIcon: const Icon(Icons.check_circle, color: lightColor),
          label: const Text('Bus stop created successfully'),
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
                : 'Failed to create bus stop',
          ),
          backgroundColor: errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        appBar: AppBar(title: const Text('New Bus Stop')),
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
                        'The form below allows you to create a new bus stop. This will be added to the list of available stops for users to select when subscribing to bus routes.',
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
              const Gap(16.0),
              Obx(
                () => PrimaryButton.label(
                  onPressed:
                      _isSubmitting || _busStopsController.isLoading.value
                      ? null
                      : _handleSubmit,
                  label: _isSubmitting || _busStopsController.isLoading.value
                      ? "Adding..."
                      : "Add stop",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
