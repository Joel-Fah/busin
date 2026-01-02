import 'package:busin/controllers/bus_stops_controller.dart';
import 'package:busin/ui/components/widgets/default_snack_bar.dart';
import 'package:busin/ui/components/widgets/form_fields/select_image.dart';
import 'package:busin/ui/components/widgets/form_fields/simple_text_field.dart';
import 'package:busin/ui/components/widgets/buttons/primary_button.dart';
import 'package:busin/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context)!;
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
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          buildSnackBar(
            prefixIcon: const Icon(Icons.check_circle, color: lightColor),
            label: Text(l10n.newStopForm_handleSubmit_success),
            backgroundColor: successColor,
          ),
        );
    } else {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          buildSnackBar(
            prefixIcon: const Icon(Icons.error, color: lightColor),
            label: Text(
              _busStopsController.error.value.isNotEmpty
                  ? _busStopsController.error.value
                  : l10n.newStopForm_handleSubmit_failed,
            ),
            backgroundColor: errorColor,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: FittedBox(
            fit: BoxFit.contain,
            child: Text(l10n.newStopForm_appBar_title),
          ),
        ),
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
                        l10n.newStopForm_listTile_infoBubble,
                        style: AppTextStyles.body.copyWith(color: infoColor),
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(24.0),
              Text(l10n.newStopForm_stopDetails, style: AppTextStyles.h2),
              const Gap(16.0),
              ImageBox(
                onImageSelected: (filePath) {
                  setState(() {
                    _pickupImageUrl = filePath;
                  });
                },
                label: l10n.newStopForm_stopDetails_image,
              ),
              const Gap(16.0),
              SimpleTextFormField(
                controller: _nameController,
                hintText: l10n.newStopForm_stopDetails_nameLabel,
                label: Text(l10n.newStopForm_stopDetails_nameHint),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.newStopForm_stopDetails_nameValidator;
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.words,
                keyboardType: TextInputType.text,
              ),
              const Gap(16.0),
              SimpleTextFormField(
                controller: _mapEmbedController,
                hintText: l10n.newStopForm_stopDetails_mapsLabel,
                label: Text(l10n.newStopForm_stopDetails_mapsHint),
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    final urlPattern = RegExp(
                      r'^https?:\/\/(www\.)?(google\.com\/maps|maps\.google\.com|maps\.app\.goo\.gl|goo\.gl)',
                      caseSensitive: false,
                    );
                    if (!urlPattern.hasMatch(value.trim())) {
                      return l10n.newStopForm_stopDetails_mapsValidator;
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
                      ? l10n.newStopForm_handleSubmit_labelLoading
                      : l10n.newStopForm_handleSubmit_label,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
