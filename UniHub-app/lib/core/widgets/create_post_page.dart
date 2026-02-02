import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase/supabase_client.dart';
import 'avatar_image.dart';
import '../../features/profile/providers/profile_providers.dart';

class CreatePostPayload {
  const CreatePostPayload({
    required this.title,
    required this.contentMarkdown,
    this.linkUrl,
    this.mediaUrl,
    this.mediaType,
  });

  final String title;
  final String contentMarkdown;
  final String? linkUrl;
  final String? mediaUrl;
  final String? mediaType;
}

class CreatePostPage extends ConsumerStatefulWidget {
  const CreatePostPage({
    super.key,
    required this.onSubmit,
    this.appBarTitle = 'Create Post',
    this.contextLabel = 'Posting to Campus feed',
    this.postButtonLabel = 'Post',
    this.mediaBucket = 'post-media',
    this.successMessage = 'Post created successfully',
    this.extraFieldsBuilder,
    this.contentPadding,
  });

  final Future<void> Function(CreatePostPayload payload) onSubmit;
  final String appBarTitle;
  final String contextLabel;
  final String postButtonLabel;
  final String mediaBucket;
  final String successMessage;
  final List<Widget> Function(BuildContext, WidgetRef)? extraFieldsBuilder;
  final EdgeInsetsGeometry? contentPadding;

  @override
  ConsumerState<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends ConsumerState<CreatePostPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _urlController = TextEditingController();
  final _contentFocusNode = FocusNode();
  final _urlFocusNode = FocusNode();
  final _contentScrollController = ScrollController();
  late final quill.QuillController _quillController;
  final _imagePicker = ImagePicker();
  bool _isSubmitting = false;
  bool _isUploadingMedia = false;
  _SelectedMediaKind? _selectedMediaKind;
  bool _showFormatOptions = false;
  bool _showUrlField = false;
  bool _boldActive = false;
  bool _italicActive = false;
  bool _strikeActive = false;
  bool _codeActive = false;
  Uint8List? _selectedMediaBytes;
  String? _selectedMediaName;
  String? _uploadedMediaUrl;
  String? _mediaUploadError;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_onFormChanged);
    _urlController.addListener(_onFormChanged);
    _contentFocusNode.addListener(_onFormChanged);
    _quillController = quill.QuillController.basic();
    _quillController.addListener(_onFormChanged);
  }

  @override
  void dispose() {
    _titleController.removeListener(_onFormChanged);
    _urlController.removeListener(_onFormChanged);
    _contentFocusNode.removeListener(_onFormChanged);
    _titleController.dispose();
    _urlController.dispose();
    _contentFocusNode.dispose();
    _urlFocusNode.dispose();
    _contentScrollController.dispose();
    _quillController.dispose();
    super.dispose();
  }

  void _onFormChanged() {
    if (!mounted) return;
    if (!_contentFocusNode.hasFocus && _showFormatOptions) {
      _showFormatOptions = false;
    }
    if (!_contentFocusNode.hasFocus) {
      _boldActive = false;
      _italicActive = false;
      _strikeActive = false;
      _codeActive = false;
    } else {
      final selectionStyle = _quillController.getSelectionStyle();
      _boldActive = selectionStyle.attributes.containsKey(
        quill.Attribute.bold.key,
      );
      _italicActive = selectionStyle.attributes.containsKey(
        quill.Attribute.italic.key,
      );
      _strikeActive = selectionStyle.attributes.containsKey(
        quill.Attribute.strikeThrough.key,
      );
      _codeActive = selectionStyle.attributes.containsKey(
        quill.Attribute.inlineCode.key,
      );
    }
    setState(() {});
  }

  void _toggleUrlField() {
    if (_showUrlField && _urlController.text.trim().isEmpty) {
      _showUrlField = false;
      _urlFocusNode.unfocus();
    } else {
      _showUrlField = true;
      _urlFocusNode.requestFocus();
    }
    setState(() {});
  }

  void _clearUrlField() {
    _urlController.clear();
    _showUrlField = false;
    _urlFocusNode.unfocus();
    setState(() {});
  }

  String _inferContentType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.mp4')) return 'video/mp4';
    if (lower.endsWith('.mov')) return 'video/quicktime';
    if (lower.endsWith('.m4v')) return 'video/x-m4v';
    if (lower.endsWith('.avi')) return 'video/x-msvideo';
    if (lower.endsWith('.webm')) return 'video/webm';
    return 'image/jpeg';
  }

  void _toggleInlineStyle(quill.Attribute attribute) {
    if (!_contentFocusNode.hasFocus) return;
    final selectionStyle = _quillController.getSelectionStyle();
    final isToggled = selectionStyle.attributes.containsKey(attribute.key);
    _quillController.formatSelection(
      isToggled ? quill.Attribute.clone(attribute, null) : attribute,
    );
  }

  void _toggleBulletList() {
    if (!_contentFocusNode.hasFocus) return;
    final selectionStyle = _quillController.getSelectionStyle();
    final listAttribute = selectionStyle.attributes[quill.Attribute.list.key];
    final isBullet = listAttribute?.value == quill.Attribute.ul.value;
    _quillController.formatSelection(
      isBullet
          ? quill.Attribute.clone(quill.Attribute.ul, null)
          : quill.Attribute.ul,
    );
  }

  String _normalizeUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return trimmed;
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    return 'https://$trimmed';
  }

  bool _isUrlValid(String value) {
    if (value.trim().isEmpty) return true;
    final normalized = _normalizeUrl(value);
    final uri = Uri.tryParse(normalized);
    if (uri == null) return false;
    final hasHttpScheme = uri.scheme == 'http' || uri.scheme == 'https';
    return hasHttpScheme && uri.host.isNotEmpty;
  }

  String _applyInlineMarkdown(String text, Map<String, dynamic> attrs) {
    if (text.isEmpty) return text;
    final isCode = attrs[quill.Attribute.inlineCode.key] == true;
    if (isCode) {
      return '`$text`';
    }
    var result = text;
    if (attrs[quill.Attribute.bold.key] == true) {
      result = '**$result**';
    }
    if (attrs[quill.Attribute.italic.key] == true) {
      result = '_${result}_';
    }
    if (attrs[quill.Attribute.strikeThrough.key] == true) {
      result = '~~$result~~';
    }
    final link = attrs[quill.Attribute.link.key];
    if (link is String && link.trim().isNotEmpty) {
      result = '[$result]($link)';
    }
    return result;
  }

  String _quillToMarkdown() {
    final delta = _quillController.document.toDelta();
    final buffer = StringBuffer();
    final lineBuffer = StringBuffer();

    void flushLine(String? listType) {
      final content = lineBuffer.toString().trimRight();
      if (listType == quill.Attribute.ul.value) {
        buffer.write(content.isEmpty ? '-' : '- $content');
      } else {
        buffer.write(content);
      }
      buffer.write('\n');
      lineBuffer.clear();
    }

    for (final op in delta.toList()) {
      if (op.data is! String) continue;
      final text = op.data as String;
      final attrs = op.attributes ?? const <String, dynamic>{};
      final parts = text.split('\n');
      for (var i = 0; i < parts.length; i += 1) {
        final segment = parts[i];
        if (segment.isNotEmpty) {
          lineBuffer.write(_applyInlineMarkdown(segment, attrs));
        }
        if (i < parts.length - 1) {
          final listType = attrs[quill.Attribute.list.key] as String?;
          flushLine(listType);
        }
      }
    }

    if (lineBuffer.isNotEmpty) {
      buffer.write(lineBuffer.toString());
    }

    return buffer.toString().replaceFirst(RegExp(r'\n+$'), '');
  }

  Future<void> _pickAndUploadMedia() async {
    if (_isUploadingMedia) return;

    final file = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1800,
    );
    if (file == null) return;

    final bytes = await file.readAsBytes();
    setState(() {
      _selectedMediaKind = _SelectedMediaKind.image;
      _selectedMediaBytes = bytes;
      _selectedMediaName = file.name;
      _uploadedMediaUrl = null;
      _mediaUploadError = null;
      _isUploadingMedia = true;
    });

    try {
    final client = SupabaseClientProvider.client;
      final userId = client.auth.currentUser?.id ?? 'anonymous';
      final timestamp = DateTime.now().toUtc().toIso8601String().replaceAll(
        ':',
        '-',
      );
      final objectPath = 'campus_posts/$userId/$timestamp-${file.name}';
      final contentType = _inferContentType(file.name);

      await client.storage
          .from(widget.mediaBucket)
          .uploadBinary(
            objectPath,
            bytes,
            fileOptions: FileOptions(contentType: contentType, upsert: true),
          );

      final publicUrl = client.storage
          .from(widget.mediaBucket)
          .getPublicUrl(objectPath);
      if (mounted) {
        setState(() {
          _uploadedMediaUrl = publicUrl;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _mediaUploadError = e.toString();
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingMedia = false);
      }
    }
  }

  Future<void> _pickAndUploadVideo() async {
    if (_isUploadingMedia) return;

    final file = await _imagePicker.pickVideo(source: ImageSource.gallery);
    if (file == null) return;

    final bytes = await file.readAsBytes();
    setState(() {
      _selectedMediaKind = _SelectedMediaKind.video;
      _selectedMediaBytes = null;
      _selectedMediaName = file.name;
      _uploadedMediaUrl = null;
      _mediaUploadError = null;
      _isUploadingMedia = true;
    });

    try {
    final client = SupabaseClientProvider.client;
      final userId = client.auth.currentUser?.id ?? 'anonymous';
      final timestamp = DateTime.now().toUtc().toIso8601String().replaceAll(
        ':',
        '-',
      );
      final objectPath = 'campus_posts/$userId/$timestamp-${file.name}';
      final contentType = _inferContentType(file.name);

      await client.storage
          .from(widget.mediaBucket)
          .uploadBinary(
            objectPath,
            bytes,
            fileOptions: FileOptions(contentType: contentType, upsert: true),
          );

      final publicUrl = client.storage
          .from(widget.mediaBucket)
          .getPublicUrl(objectPath);
      if (mounted) {
        setState(() {
          _uploadedMediaUrl = publicUrl;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _mediaUploadError = e.toString();
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingMedia = false);
      }
    }
  }

  void _removeMedia() {
    setState(() {
      _selectedMediaKind = null;
      _selectedMediaBytes = null;
      _selectedMediaName = null;
      _uploadedMediaUrl = null;
      _mediaUploadError = null;
    });
  }

  Future<void> _handleSubmit() async {
    if (_isUploadingMedia) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please wait for the media upload.')),
      );
      return;
    }
    if (_selectedMediaKind != null && _uploadedMediaUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload the selected media.')),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final mediaType = _selectedMediaName != null
          ? _inferContentType(_selectedMediaName!)
          : null;
      final markdownContent = _quillToMarkdown().trim();
      final urlValue = _normalizeUrl(_urlController.text);
      final payload = CreatePostPayload(
        title: _titleController.text.trim(),
        contentMarkdown: markdownContent,
        linkUrl: urlValue.isEmpty ? null : urlValue,
        mediaUrl: _uploadedMediaUrl,
        mediaType: _uploadedMediaUrl == null ? null : mediaType,
      );
      await widget.onSubmit(payload);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(widget.successMessage)));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profileAsync = ref.watch(profileProvider);
    final profile = profileAsync.asData?.value;
    final displayName = (profile?.displayName?.trim().isNotEmpty == true)
        ? profile!.displayName!
        : (profile?.username ?? 'You');
    final avatarUrl = profile?.avatarUrl;
    final hasRequiredFields = _titleController.text.trim().isNotEmpty;
    final urlValid = _isUrlValid(_urlController.text);
    final canSubmit =
        hasRequiredFields &&
        urlValid &&
        !_isSubmitting &&
        !_isUploadingMedia &&
        (_selectedMediaKind == null || _uploadedMediaUrl != null);
    final postButtonBg = hasRequiredFields && urlValid && !_isUploadingMedia
        ? theme.colorScheme.primary
        : theme.colorScheme.surfaceVariant;
    final postButtonFg = hasRequiredFields && urlValid && !_isUploadingMedia
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurfaceVariant;
    final isBodyFocused = _contentFocusNode.hasFocus;
    final toolbarIconColor = theme.colorScheme.onSurface;
    final formatControlColor = theme.colorScheme.onSurface;
    final formatActiveColor = Colors.black;
    final formatInactiveColor = theme.colorScheme.onSurface.withOpacity(0.35);
    final formatDisabledColor = theme.colorScheme.onSurfaceVariant.withOpacity(
      0.35,
    );
    final formatEnabled = isBodyFocused;
    final baseStyles = quill.DefaultStyles.getInstance(context);
    final bodyTextStyle = theme.textTheme.bodyLarge?.copyWith(
      color: theme.colorScheme.onSurface,
    );
    final placeholderTextStyle = theme.textTheme.bodyLarge?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final editorStyles = quill.DefaultStyles(
      paragraph: baseStyles.paragraph?.copyWith(
        style: bodyTextStyle ?? baseStyles.paragraph!.style,
      ),
      placeHolder: baseStyles.placeHolder?.copyWith(
        style: placeholderTextStyle ?? baseStyles.placeHolder!.style,
      ),
    );

    InputDecoration buildMinimalDecoration({
      required String hintText,
      TextStyle? hintStyle,
      EdgeInsets contentPadding = EdgeInsets.zero,
      String? errorText,
    }) {
      return InputDecoration(
        hintText: hintText,
        hintStyle: hintStyle,
        isDense: true,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: contentPadding,
        filled: true,
        fillColor: theme.colorScheme.background,
        counterText: '',
        errorText: errorText,
      );
    }

    final uploadStatusText = _isUploadingMedia
        ? 'Uploading...'
        : _mediaUploadError != null
        ? 'Upload failed'
        : _uploadedMediaUrl != null
        ? 'Uploaded'
        : 'Ready to upload';
    final attachmentFillColor = theme.colorScheme.background;
    final attachmentBorderColor = _mediaUploadError != null
        ? theme.colorScheme.error.withOpacity(0.35)
        : theme.colorScheme.outlineVariant;
    final statusChipColor = _mediaUploadError != null
        ? theme.colorScheme.errorContainer
        : _uploadedMediaUrl != null
        ? theme.colorScheme.secondaryContainer
        : theme.colorScheme.surface;
    final statusChipBorderColor = _mediaUploadError != null
        ? theme.colorScheme.error.withOpacity(0.4)
        : theme.colorScheme.outlineVariant;
    final statusChipTextColor = _mediaUploadError != null
        ? theme.colorScheme.onErrorContainer
        : _uploadedMediaUrl != null
        ? theme.colorScheme.onSecondaryContainer
        : theme.colorScheme.onSurfaceVariant;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.background,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        leading: const BackButton(),
        title: Text(
          widget.appBarTitle,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 21,
            color: theme.colorScheme.onBackground,
          ),
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton(
              onPressed: canSubmit ? _handleSubmit : null,
              style: FilledButton.styleFrom(
                minimumSize: const Size(72, 36),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                backgroundColor: postButtonBg,
                foregroundColor: postButtonFg,
                textStyle: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(widget.postButtonLabel),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding:
                      widget.contentPadding ??
                      const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  children: [
                    Row(
                      children: [
                        AvatarImage(
                          name: displayName,
                          imageUrl: avatarUrl,
                          radius: 22,
                          backgroundColor: theme.colorScheme.primaryContainer,
                          textStyle: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.contextLabel,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _titleController,
                      decoration: buildMinimalDecoration(
                        hintText: 'Title',
                        hintStyle: theme.textTheme.headlineSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLength: 100,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) {
                        if (_showUrlField) {
                          _urlFocusNode.requestFocus();
                        } else {
                          _contentFocusNode.requestFocus();
                        }
                      },
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    if (_showUrlField) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _urlController,
                              focusNode: _urlFocusNode,
                              keyboardType: TextInputType.url,
                              textInputAction: TextInputAction.next,
                              decoration: buildMinimalDecoration(
                                hintText: 'URL',
                                hintStyle: theme.textTheme.titleMedium
                                    ?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                    ),
                                errorText: urlValid
                                    ? null
                                    : 'Please enter a valid URL',
                              ),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface,
                              ),
                              onSubmitted: (_) =>
                                  _contentFocusNode.requestFocus(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Material(
                            color: theme.colorScheme.surfaceVariant,
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: _clearUrlField,
                              child: const Padding(
                                padding: EdgeInsets.all(8),
                                child: Icon(Icons.close_rounded, size: 18),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.only(top: 6),
                      constraints: const BoxConstraints(minHeight: 160),
                      child: quill.QuillEditor.basic(
                        controller: _quillController,
                        focusNode: _contentFocusNode,
                        scrollController: _contentScrollController,
                        config: quill.QuillEditorConfig(
                          placeholder: 'Body text (optional)',
                          padding: EdgeInsets.zero,
                          scrollable: false,
                          minHeight: 160,
                          customStyles: editorStyles,
                        ),
                      ),
                    ),
                    if (widget.extraFieldsBuilder != null) ...[
                      const SizedBox(height: 16),
                      ...widget.extraFieldsBuilder!(context, ref),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                color: theme.colorScheme.background,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_selectedMediaKind != null)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: attachmentFillColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: attachmentBorderColor),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            if (_selectedMediaKind ==
                                    _SelectedMediaKind.image &&
                                _selectedMediaBytes != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.memory(
                                  _selectedMediaBytes!,
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                ),
                              )
                            else
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceVariant,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  LucideIcons.video,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedMediaName ??
                                        (_selectedMediaKind ==
                                                _SelectedMediaKind.video
                                            ? 'Selected video'
                                            : 'Selected image'),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusChipColor,
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: statusChipBorderColor,
                                      ),
                                    ),
                                    child: Text(
                                      uploadStatusText,
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            color: statusChipTextColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: _isUploadingMedia
                                  ? null
                                  : _removeMedia,
                              icon: const Icon(LucideIcons.x),
                            ),
                          ],
                        ),
                      ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) {
                        final curved = CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                          reverseCurve: Curves.easeInCubic,
                        );
                        final offset = Tween<Offset>(
                          begin: const Offset(0.14, 0),
                          end: Offset.zero,
                        ).animate(curved);
                        return FadeTransition(
                          opacity: curved,
                          child: SizeTransition(
                            axis: Axis.horizontal,
                            sizeFactor: curved,
                            child: SlideTransition(
                              position: offset,
                              child: child,
                            ),
                          ),
                        );
                      },
                      child: _showFormatOptions
                          ? Row(
                              key: const ValueKey('formatRow'),
                              children: [
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _showFormatOptions = false;
                                    });
                                  },
                                  icon: const Icon(LucideIcons.x),
                                  color: formatControlColor,
                                  splashRadius: 18,
                                  iconSize: 20,
                                  padding: const EdgeInsets.all(4),
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                SizedBox(
                                  height: 18,
                                  child: VerticalDivider(
                                    color: theme.colorScheme.outlineVariant,
                                    thickness: 1,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                IconButton(
                                  onPressed: () =>
                                      _toggleInlineStyle(quill.Attribute.bold),
                                  icon: const Icon(LucideIcons.bold),
                                  color: _boldActive
                                      ? formatActiveColor
                                      : formatInactiveColor,
                                  splashRadius: 18,
                                  iconSize: 20,
                                  padding: const EdgeInsets.all(4),
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _toggleInlineStyle(
                                    quill.Attribute.italic,
                                  ),
                                  icon: const Icon(LucideIcons.italic),
                                  color: _italicActive
                                      ? formatActiveColor
                                      : formatInactiveColor,
                                  splashRadius: 18,
                                  iconSize: 20,
                                  padding: const EdgeInsets.all(4),
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _toggleInlineStyle(
                                    quill.Attribute.strikeThrough,
                                  ),
                                  icon: const Icon(LucideIcons.strikethrough),
                                  color: _strikeActive
                                      ? formatActiveColor
                                      : formatInactiveColor,
                                  splashRadius: 18,
                                  iconSize: 20,
                                  padding: const EdgeInsets.all(4),
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _toggleInlineStyle(
                                    quill.Attribute.inlineCode,
                                  ),
                                  icon: const Icon(LucideIcons.code),
                                  color: _codeActive
                                      ? formatActiveColor
                                      : formatInactiveColor,
                                  splashRadius: 18,
                                  iconSize: 20,
                                  padding: const EdgeInsets.all(4),
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              key: const ValueKey('toolbarRow'),
                              children: [
                                IconButton(
                                  onPressed: _toggleUrlField,
                                  icon: const Icon(LucideIcons.link),
                                  color: toolbarIconColor,
                                  splashRadius: 18,
                                  iconSize: 20,
                                  padding: const EdgeInsets.all(6),
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                ),
                                IconButton(
                                  onPressed: _isUploadingMedia
                                      ? null
                                      : _pickAndUploadMedia,
                                  icon: const Icon(LucideIcons.image),
                                  color:
                                      _selectedMediaKind ==
                                          _SelectedMediaKind.image
                                      ? theme.colorScheme.primary
                                      : toolbarIconColor,
                                  splashRadius: 18,
                                  iconSize: 20,
                                  padding: const EdgeInsets.all(6),
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                ),
                                IconButton(
                                  onPressed: _isUploadingMedia
                                      ? null
                                      : _pickAndUploadVideo,
                                  icon: const Icon(LucideIcons.video),
                                  color:
                                      _selectedMediaKind ==
                                          _SelectedMediaKind.video
                                      ? theme.colorScheme.primary
                                      : toolbarIconColor,
                                  splashRadius: 18,
                                  iconSize: 20,
                                  padding: const EdgeInsets.all(6),
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                ),
                                IconButton(
                                  onPressed: _toggleBulletList,
                                  icon: const Icon(LucideIcons.list),
                                  color: toolbarIconColor,
                                  splashRadius: 18,
                                  iconSize: 20,
                                  padding: const EdgeInsets.all(6),
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                SizedBox(
                                  height: 20,
                                  child: VerticalDivider(
                                    color: theme.colorScheme.outlineVariant,
                                    thickness: 1,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                TextButton(
                                  onPressed: formatEnabled
                                      ? () {
                                          setState(() {
                                            _showFormatOptions = true;
                                          });
                                        }
                                      : null,
                                  style: ButtonStyle(
                                    foregroundColor:
                                        MaterialStateProperty.resolveWith((
                                          states,
                                        ) {
                                          if (states.contains(
                                            MaterialState.disabled,
                                          )) {
                                            return formatDisabledColor;
                                          }
                                          return formatControlColor;
                                        }),
                                    padding: MaterialStateProperty.all(
                                      const EdgeInsets.symmetric(horizontal: 6),
                                    ),
                                    minimumSize: MaterialStateProperty.all(
                                      const Size(36, 36),
                                    ),
                                  ),
                                  child: Text(
                                    'Aa',
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: formatEnabled
                                          ? formatControlColor
                                          : formatDisabledColor,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                    if (_isUploadingMedia)
                      const Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: LinearProgressIndicator(),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _SelectedMediaKind { image, video }
