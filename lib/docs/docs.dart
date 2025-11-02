import 'package:busin/ui/components/widgets/loading_indicator.dart';
import 'package:busin/ui/components/widgets/secondary_button.dart';
import 'package:busin/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:busin/api/docs_api.dart';
import 'package:busin/ui/components/widgets/markdown_styling.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../utils/constants.dart';

class DocsPage extends StatefulWidget {
  static const String routeName = '/docs';
  final DocsTopic topic;
  final String baseUrl; // the server base hosting docs/<file>.md

  const DocsPage({super.key, required this.topic, required this.baseUrl});

  @override
  State<DocsPage> createState() => _DocsPageState();
}

class _DocsPageState extends State<DocsPage> {
  late final DocsApi _api;
  String? _content;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _api = DocsApi(baseUrl: widget.baseUrl);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _api.fetchMarkdown(widget.topic);
      if (!mounted) return;
      setState(() {
        _content = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = switch (widget.topic) {
      DocsTopic.student => 'BusIn for Students',
      DocsTopic.admin => 'BusIn for Admins',
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: HugeIcon(icon: HugeIcons.strokeRoundedRefresh),
            onPressed: _loading ? null : _load,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return Center(
        child: Column(
          spacing: 8.0,
          mainAxisSize: MainAxisSize.min,
          children: [
            const LoadingIndicator(),
            Text(
              'Loading content, please wait...',
              style: AppTextStyles.body.copyWith(
                color: themeController.isDark
                    ? lightColor.withValues(alpha: 0.75)
                    : seedColor.withValues(alpha: 0.75),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const HugeIcon(
                icon: HugeIcons.strokeRoundedConnect,
                size: 32,
                color: greyColor,
              ),
              const SizedBox(height: 12),
              Text(
                _error!,
                style: AppTextStyles.body.copyWith(color: greyColor.withValues(alpha: 0.5)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              SecondaryButton.icon(
                onPressed: _load,
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedRefresh,
                  size: 20.0,
                ),
                label: Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    return _content != null
        ? SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: MarkdownStyledView(data: _content!),
          )
        : const SizedBox.shrink();
  }
}

/// Quick helpers to navigate to the docs page from anywhere using go_router.
void openStudentDocs(BuildContext context, String baseUrl) {
  context.pushNamed(
    removeLeadingSlash(DocsPage.routeName),
    pathParameters: {'topic': DocsTopic.student.fileName, 'baseUrl': baseUrl},
  );
}

void openAdminDocs(BuildContext context, String baseUrl) {
  context.pushNamed(
    removeLeadingSlash(DocsPage.routeName),
    pathParameters: {'topic': DocsTopic.admin.fileName, 'baseUrl': baseUrl},
  );
}
