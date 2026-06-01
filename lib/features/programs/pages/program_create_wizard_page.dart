import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../_shared/exceptions/app_error.dart';
import '../../../_shared/services/error_display_service.dart';
import '../../../_shared/theme/app_colors.dart';
import '../../templates/managers/template_manager.dart';
import '../pages/program_store_selector_page.dart';
import '../services/program_api_service.dart';
import '../widgets/program_wizard_steps.dart';

/// In-wizard draft state (transient — no DI, no persistence).
class ProgramDraft {
  String title = '';
  String category = '';
  DateTime? deadline;
  String? templateId;
  String? templateTitle;
  List<String> storeIds = [];
}

/// Multi-step wizard for creating and issuing a new Program.
///
/// Steps: (1) Info → (2) Template → (3) Stores → (4) Review
///
/// The "Issue Program" button lives in the bottom action bar and is
/// ALWAYS present in the widget tree (disabled until all fields are valid).
/// This guarantees `find.byKey(Key('issue_program_button'))` works from
/// any step without requiring navigation — meeting TC-04/05/06 contracts.
///
/// State is held in-widget as [ProgramDraft]. No DI scope push.
/// On success, pops with `{ 'programId': ..., 'assignmentCount': ... }`.
class ProgramCreateWizardPage extends StatefulWidget {
  const ProgramCreateWizardPage({super.key});

  @override
  State<ProgramCreateWizardPage> createState() =>
      _ProgramCreateWizardPageState();
}

class _ProgramCreateWizardPageState extends State<ProgramCreateWizardPage> {
  final _api = GetIt.instance<ProgramApiService>();
  final _templateManager = GetIt.instance<TemplateManager>();

  final _draft = ProgramDraft();

  int _currentStep = 0;
  bool _isSubmitting = false;

  bool get _canIssue =>
      _draft.title.isNotEmpty &&
      _draft.deadline != null &&
      _draft.templateId != null &&
      _draft.storeIds.isNotEmpty;

  void _nextStep() {
    if (_currentStep < 3) setState(() => _currentStep++);
  }

  void _prevStep() {
    if (_currentStep > 0) setState(() => _currentStep--);
  }

  Future<void> _pickStores() async {
    final result = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ProgramStoreSelectorPage(initialSelectedIds: _draft.storeIds),
      ),
    );
    if (result != null && mounted) {
      setState(() => _draft.storeIds = result);
    }
  }

  Future<void> _pickTemplate() async {
    // Start network fetch but do not block UI
    _templateManager.loadTemplates();

    await showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      builder: (ctx) => TemplatePicker(
        templateManager: _templateManager,
        onSelected: (t) {
          setState(() {
            _draft.templateId = t.id;
            _draft.templateTitle = t.title;
          });
          Navigator.maybePop(ctx);
        },
      ),
    );
  }

  Future<void> _submit() async {
    if (!_canIssue || _isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      final result = await _api.createProgram(
        title: _draft.title,
        category: _draft.category,
        deadline: _draft.deadline!,
        templateId: _draft.templateId!,
        storeIds: _draft.storeIds,
      );
      if (!mounted) return;
      Navigator.of(context).pop(result);
    } on DioException catch (e) {
      if (!mounted) return;
      GetIt.instance<ErrorDisplayService>().show(AppError.fromDioException(e));
    } catch (_) {
      if (!mounted) return;
      GetIt.instance<ErrorDisplayService>().show(
        const AppError(
          code: 'unknown',
          message: 'Could not create campaign. Please try again.',
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Campaign'),
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _prevStep,
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.maybePop(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Step indicator ──
          _StepIndicator(currentStep: _currentStep),
          // ── Step content ──
          Expanded(
            child: IndexedStack(
              index: _currentStep,
              children: [
                StepInfo(
                  draft: _draft,
                  onChanged: () => setState(() {}),
                  onNext: _nextStep,
                ),
                StepTemplate(
                  draft: _draft,
                  onPickTemplate: _pickTemplate,
                  onNext: _nextStep,
                ),
                StepStores(
                  draft: _draft,
                  onPickStores: _pickStores,
                  onNext: _nextStep,
                ),
                StepReview(draft: _draft),
              ],
            ),
          ),
          // ── Persistent bottom action bar ──
          // The Issue button is ALWAYS in the widget tree (key always findable).
          _WizardActionBar(
            canIssue: _canIssue,
            isSubmitting: _isSubmitting,
            onIssue: _submit,
          ),
        ],
      ),
    );
  }
}

/// Linear step indicator dots.
class _StepIndicator extends StatelessWidget {
  final int currentStep;
  const _StepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(4, (i) {
          final active = i == currentStep;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: active ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: active
                  ? AppColors.featherGreen
                  : (isLight ? AppColors.swan : AppColors.charcoal),
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      ),
    );
  }
}

/// Bottom action bar — always present so TC-04/05/06 can find 'issue_program_button'.
class _WizardActionBar extends StatelessWidget {
  final bool canIssue;
  final bool isSubmitting;
  final VoidCallback onIssue;

  const _WizardActionBar({
    required this.canIssue,
    required this.isSubmitting,
    required this.onIssue,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SizedBox(
          width: double.infinity,
          height: 50.0,
          child: ElevatedButton(
            key: const Key('issue_program_button'),
            onPressed: canIssue && !isSubmitting ? onIssue : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.featherGreen,
              foregroundColor: Colors.white,
              disabledBackgroundColor: isLight
                  ? AppColors.swan
                  : AppColors.charcoal,
              disabledForegroundColor: isLight
                  ? AppColors.wolf
                  : AppColors.hare,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
            ),
            child: isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Issue Campaign',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
          ),
        ),
      ),
    );
  }
}
