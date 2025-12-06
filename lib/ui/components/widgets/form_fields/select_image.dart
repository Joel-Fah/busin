import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dotted_border/dotted_border.dart';

import '../../../../utils/constants.dart';
import '../../../../utils/utils.dart';
import '../default_snack_bar.dart';

class ImageBox extends StatefulWidget {
  final Function(String) onImageSelected;
  final String label;
  final int maxSizeInMB; // Maximum size in MB
  final String? initialImageUrl; // Initial image URL for updates

  const ImageBox({
    super.key,
    required this.onImageSelected,
    required this.label,
    this.maxSizeInMB = 2, // Default to 2MB
    this.initialImageUrl, // Optional initial image URL
  });

  @override
  State<ImageBox> createState() => _ImageBoxState();
}

class _ImageBoxState extends State<ImageBox> {
  File? _selectedImage;
  String? _imageUrl;
  double? _imageAspectRatio;

  @override
  @override
  void initState() {
    super.initState();
    if (widget.initialImageUrl != null && widget.initialImageUrl!.isNotEmpty) {
      _imageUrl = widget.initialImageUrl;
      _resolveNetworkImage(widget.initialImageUrl!);
    }
  }

  @override
  void didUpdateWidget(covariant ImageBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newUrl = widget.initialImageUrl;
    if (newUrl != null &&
        newUrl.isNotEmpty &&
        newUrl != oldWidget.initialImageUrl) {
      _selectedImage = null;
      _imageUrl = newUrl;
      _resolveNetworkImage(newUrl);
    }
  }

  Future<void> _resolveNetworkImage(String url) async {
    try {
      final provider = NetworkImage(url);
      final completer = Completer<ImageInfo>();
      final stream = provider.resolve(const ImageConfiguration());
      late ImageStreamListener listener;
      listener = ImageStreamListener(
            (info, _) {
          completer.complete(info);
        },
        onError: (error, stackTrace) {
          completer.completeError(error, stackTrace);
        },
      );
      stream.addListener(listener);
      final info = await completer.future;
      stream.removeListener(listener);

      final ratio = info.image.height == 0
          ? null
          : info.image.width / info.image.height;
      info.image.dispose();

      if (mounted) {
        setState(() => _imageAspectRatio = ratio);
      }
    } catch (_) {}
  }

  Future<double?> _calculateAspectRatioFromFile(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final decoded = await decodeImageFromList(bytes);
      final ratio = decoded.height == 0
          ? null
          : decoded.width / decoded.height;
      decoded.dispose();
      return ratio;
    } catch (_) {
      return null;
    }
  }


  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return;

      final file = File(pickedFile.path);
      final fileSizeInMB = (await file.length()) / (1024 * 1024);

      if (fileSizeInMB > widget.maxSizeInMB) {
        if (mounted) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              buildSnackBar(
                backgroundColor: errorColor,
                prefixIcon: HugeIcon(icon: errorIcon, color: lightColor),
                label: Text(
                  'The image size should not be more than ${widget.maxSizeInMB}MB',
                ),
              ),
            );
        }
        return;
      }

      final ratio = await _calculateAspectRatioFromFile(file);
      if (!mounted) return;

      setState(() {
        _selectedImage = file;
        _imageUrl = null;
        _imageAspectRatio = ratio;
      });

      widget.onImageSelected(pickedFile.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            buildSnackBar(
              backgroundColor: errorColor,
              prefixIcon: HugeIcon(icon: errorIcon, color: lightColor),
              label: Text('Error during image upload: $e'),
            ),
          );
      }
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _imageUrl = null;
      _imageAspectRatio = null;
    });
    widget.onImageSelected('');
  }

  bool get _hasImage =>
      _selectedImage != null || (_imageUrl != null && _imageUrl!.isNotEmpty);

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      color: Colors.transparent,
      borderRadius: borderRadius * 2.25,
      // clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: !_hasImage ? _pickImage : null,
        borderRadius: borderRadius * 2.25,
        child: DottedBorder(
          options: const RoundedRectDottedBorderOptions(
            radius: Radius.circular(20.0),
            dashPattern: const [4, 6, 8, 10],
            strokeWidth: 1.5,
            strokeCap: StrokeCap.round,
            padding: EdgeInsets.all(6.0),
            color: seedColor,
          ),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: borderRadius * 1.5,
              color: seedPalette.shade50,
              gradient: LinearGradient(
                colors: themeController.isDark
                    ? [
                        lightColor.withValues(alpha: 0.08),
                        lightColor.withValues(alpha: 0.03),
                      ]
                    : [
                        seedPalette.shade50.withValues(alpha: 0.8),
                        seedPalette.shade50.withValues(alpha: 0.3),
                      ],
              ),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: _hasImage ? 0 : 160.0,
              ),
              child: ClipRRect(
                borderRadius: borderRadius * 1.75,
                clipBehavior: Clip.hardEdge,
                child: _hasImage
                    ? LayoutBuilder(
                  builder: (context, constraints) {
                    final availableWidth = constraints.maxWidth.isFinite
                        ? constraints.maxWidth
                        : MediaQuery.of(context).size.width;
                    final ratio = _imageAspectRatio;
                    final height = ratio != null && ratio > 0
                        ? availableWidth / ratio
                        : 160.0;

                    return SizedBox(
                      width: double.infinity,
                      height: height,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: _selectedImage != null
                                ? Image.file(
                              _selectedImage!,
                              fit: BoxFit.cover,
                            )
                                : Image.network(
                              _imageUrl!,
                              fit: BoxFit.cover,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) {
                                  return child;
                                }
                                return Center(
                                  child: CircularProgressIndicator(
                                    value:
                                    loadingProgress
                                        .expectedTotalBytes !=
                                        null
                                        ? loadingProgress
                                        .cumulativeBytesLoaded /
                                        loadingProgress
                                            .expectedTotalBytes!
                                        : null,
                                  ),
                                );
                              },
                              errorBuilder:
                                  (context, error, stackTrace) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment:
                                    MainAxisAlignment.center,
                                    children: [
                                      HugeIcon(
                                        icon: warningIcon,
                                        color: errorColor,
                                        size: 32,
                                      ),
                                      const Gap(8.0),
                                      Text(
                                        'Loading error',
                                        style: AppTextStyles.small
                                            .copyWith(
                                          color: errorColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          Positioned(
                            bottom: 0.0,
                            right: 0.0,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Change',
                                  onPressed: _pickImage,
                                  color: accentColor,
                                  icon: const HugeIcon(
                                    icon:
                                    HugeIcons.strokeRoundedCardExchange01,
                                    size: 20,
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Remove',
                                  onPressed: _removeImage,
                                  color: errorColor,
                                  icon: const HugeIcon(
                                    icon: HugeIcons.strokeRoundedDelete03,
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                )
                    : Center(
                        child: Column(
                          spacing: 16.0,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            HugeIcon(
                              icon: HugeIcons.strokeRoundedImageAdd02,
                              color: seedColor,
                            ),
                            Column(
                              children: [
                                Text(widget.label, style: AppTextStyles.body),
                                Text(
                                  '(.png, .jpg/.jpeg, .tiff | ${widget.maxSizeInMB}MB max)',
                                  style: AppTextStyles.small.copyWith(
                                    color: greyColor,
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
