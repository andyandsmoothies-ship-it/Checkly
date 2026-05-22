// ignore_for_file: invalid_use_of_protected_member
part of 'template_builder_page.dart';

extension _TemplateBuilderLogic on _TemplateBuilderPageState {
  Future<void> _loadExistingTemplate() async {
    await _manager.loadTemplateTree(widget.templateId);
    final tree = _manager.selectedTemplate.value;
    if (tree != null) {
      _titleCtrl.text = tree.title;
      _descCtrl.text = tree.description ?? '';
      _type = tree.type;
      _version = tree.version;
      _sections = tree.groups.map((g) => EditableGroup.fromDto(g)).toList();

      // Parse scoring config
      if (tree.scoringLogicConfig != null &&
          tree.scoringLogicConfig!.isNotEmpty) {
        try {
          final config =
              json.decode(tree.scoringLogicConfig!) as Map<String, dynamic>;
          _ccpOverride = config['ccpOverride'] == true;
          _riskOverride = config['riskOverride'] == true;
          _weightedDensity = config['weightedDensity'] == true;
          _confirmCorrect = config['confirmCorrect'] == true;
          _progressiveRepeat = config['progressiveRepeat'] == true;
          _scoringMode = (config['scoringMode'] as String?) ?? 'penalty';
          if (config['deadlineDays'] != null) {
            _deadlineCtrl.text = config['deadlineDays'].toString();
          }
          if (config['reminderDays'] != null) {
            _reminderCtrl.text = config['reminderDays'].toString();
          }
        } catch (e) {
          debugPrint('ScoringLogicConfig parse error: $e');
        }
      }
    }
    setState(() {
      _loading = false;
      _isDirty = false; // Initial load is not a user edit
    });
  }

  String _buildScoringConfig() {
    return buildScoringLogicConfig(
      scoringMode: _scoringMode,
      ccpOverride: _ccpOverride,
      riskOverride: _riskOverride,
      weightedDensity: _weightedDensity,
      confirmCorrect: _confirmCorrect,
      progressiveRepeat: _progressiveRepeat,
      deadlineDays: _deadlineCtrl.text,
      reminderDays: _reminderCtrl.text,
    );
  }

  List<Map<String, dynamic>> _buildGroups() {
    return buildGroupsPayload(
      groups: _sections,
      confirmCorrect: _confirmCorrect,
      isEditMode: true,
    );
  }

  Future<void> _save() async {
    final errors = _validate();
    if (errors.hasAny) {
      setState(() => _validationErrors = errors);
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _scrollToFirstError(),
      );
      return;
    }
    setState(() {
      _validationErrors = null;
      _saving = true;
    });

    final templateId = _isNew ? null : widget.templateId;

    try {
      // Save template + groups atomically (server handles delete reconciliation)
      await _manager.saveTemplate(
        id: templateId,
        title: _titleCtrl.text.trim(),
        type: _type,
        description: _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
        scoringLogicConfig: _buildScoringConfig(),
        version: _version,
        groups: _buildGroups(),
      );

      if (mounted) {
        setState(() => _isDirty = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isNew ? 'Template created!' : 'Template saved!'),
          ),
        );
        context.pop();
      }
    } on DioException catch (e) {
      if (mounted) {
        _di<ErrorDisplayService>().show(AppError.fromDioException(e));
      }
    } catch (e) {
      if (mounted) {
        _di<ErrorDisplayService>().show(
          const AppError(
            code: 'unknown',
            message:
                'We hit a snag saving this. Your progress is kept safely on your device. Please check your network connection to sync.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
