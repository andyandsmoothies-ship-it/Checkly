import 'package:flutter/material.dart';
import '../../../../_shared/services/answer_input.dart';
import '../../../../_shared/services/criterion_input.dart';
import '../../../../_shared/services/scoring_engine.dart';
import '../../../../_shared/services/scoring_input.dart';
import '../../../../_shared/services/scoring_mode.dart';
import '../../../../_shared/services/scoring_result.dart';
import '../../../../_shared/services/section_input.dart';
import '../../../../_shared/services/subsection_input.dart';
import '../../../../_shared/widgets/primitives/stroke_card.dart';
import '../../../../_shared/widgets/primitives/pill_chip.dart';
import '../../models/editable_criterion.dart';
import '../../models/editable_group.dart';

/// Live Score Simulator Widget
class LiveScoreSimulator extends StatefulWidget {
  final List<EditableGroup> sections;
  final String scoringMode;
  final bool progressiveRepeat;

  const LiveScoreSimulator({
    super.key,
    required this.sections,
    required this.scoringMode,
    required this.progressiveRepeat,
  });

  @override
  State<LiveScoreSimulator> createState() => _LiveScoreSimulatorState();
}

class _LiveScoreSimulatorState extends State<LiveScoreSimulator> {
  final Map<String, bool> _criterionPassing = {};
  bool _globalRisk = false;

  bool _isPassing(String id) {
    return _criterionPassing[id] ?? true;
  }

  ScoringMode _parseScoringMode(String mode) {
    switch (mode.toLowerCase()) {
      case 'penalty':
        return ScoringMode.penalty;
      case 'accumulation':
        return ScoringMode.accumulation;
      case 'checklist':
        return ScoringMode.checklist;
      case 'survey':
        return ScoringMode.survey;
      default:
        return ScoringMode.penalty;
    }
  }

  List<SectionInput> _mapSections() {
    return widget.sections.map((g) {
      // Flat criteria
      final flat = g.criteria.map((c) {
        return CriterionInput(
          id: c.id,
          groupId: g.id,
          pointsWeight: double.tryParse(c.pointsCtrl.text) ?? 0.0,
          isCcp: c.isCcp,
          isRisk: c.isRisk,
          minusImpact:
              double.tryParse(c.minusImpactCtrl.text) ??
              (c.inputType == 'pass_fail' ? 1.0 : null),
          maxDeductionPoints: double.tryParse(c.maxDeductionCtrl.text),
          inputType: c.inputType,
        );
      }).toList();

      // Subsections
      final subs = g.subSections.map((sub) {
        final subCriteria = sub.criteria.map((c) {
          return CriterionInput(
            id: c.id,
            groupId: sub.id,
            pointsWeight: double.tryParse(c.pointsCtrl.text) ?? 0.0,
            isCcp: c.isCcp,
            isRisk: c.isRisk,
            minusImpact:
                double.tryParse(c.minusImpactCtrl.text) ??
                (c.inputType == 'pass_fail' ? 1.0 : null),
            maxDeductionPoints: double.tryParse(c.maxDeductionCtrl.text),
            inputType: c.inputType,
          );
        }).toList();

        return SubsectionInput(
          id: sub.id,
          title: sub.titleCtrl.text,
          maxPoints: double.tryParse(sub.maxPointsCtrl.text) ?? 0.0,
          criteria: subCriteria,
        );
      }).toList();

      return SectionInput(
        id: g.id,
        weight: double.tryParse(g.weightCtrl.text) ?? 0.0,
        maxDeductionPoints: double.tryParse(g.maxPointsCtrl.text),
        subsections: subs,
        criteria: flat,
      );
    }).toList();
  }

  List<AnswerInput> _mapAnswers() {
    final list = <AnswerInput>[];
    void addCriteriaAnswers(List<EditableCriterion> criteria) {
      for (final c in criteria) {
        final passing = _isPassing(c.id);
        list.add(
          AnswerInput(
            criteriaId: c.id,
            value: passing ? 'conform' : 'non_conform',
            numericValue: passing ? 0.0 : 1.0,
            isRisk: c.isRisk && !passing,
            isCcp: c.isCcp && !passing,
          ),
        );
      }
    }

    for (final g in widget.sections) {
      addCriteriaAnswers(g.criteria);
      for (final sub in g.subSections) {
        addCriteriaAnswers(sub.criteria);
      }
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final mode = _parseScoringMode(widget.scoringMode);
    final sectionInputs = _mapSections();
    final answerInputs = _mapAnswers();

    final input = ScoringInput(
      sections: sectionInputs,
      answers: answerInputs,
      scoringMode: mode,
      progressiveRepeatPenalty: widget.progressiveRepeat,
      hasGlobalRisk: _globalRisk,
    );

    final result = ScoringEngine.calculate(input);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Title/Header
        Text(
          'Live Score Simulator',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),

        // Score Display panel
        StrokeCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SIMULATED SCORE',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (mode == ScoringMode.survey) ...[
                const PillChip(
                  label: 'Survey — no score',
                  type: PillChipType.blue,
                ),
              ] else if (result.totalScore == null) ...[
                const PillChip(
                  label: 'Mixed — score will be NULL',
                  type: PillChipType.yellow,
                ),
              ] else ...[
                Text(
                  '${result.totalScore!.toStringAsFixed(2)}%',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
              if (result.hasRiskFailure) ...[
                const SizedBox(height: 8),
                PillChip(
                  label: _globalRisk ? 'GLOBAL RISK ACTIVE' : 'RISK FAILURE',
                  type: PillChipType.red,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Questions List
        Text(
          'QUESTIONS',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...widget.sections.expand((g) {
          final items = <Widget>[];
          if (g.criteria.isNotEmpty || g.subSections.isNotEmpty) {
            items.add(
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  g.titleCtrl.text.isEmpty
                      ? 'Untitled Section'
                      : g.titleCtrl.text,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Colors.grey,
                  ),
                ),
              ),
            );
          }

          void addCriteriaWidgets(List<EditableCriterion> criteria) {
            for (final c in criteria) {
              if (c.inputType == 'pass_fail') {
                items.add(
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: StrokeCard(
                      child: SwitchListTile(
                        title: Text(
                          c.labelCtrl.text.isEmpty
                              ? 'Untitled Question'
                              : c.labelCtrl.text,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Points: ${c.pointsCtrl.text.isEmpty ? "0" : c.pointsCtrl.text}${c.isRisk ? " • [RISK]" : ""}',
                        ),
                        value: _isPassing(c.id),
                        onChanged: (val) {
                          setState(() {
                            _criterionPassing[c.id] = val;
                          });
                        },
                      ),
                    ),
                  ),
                );
              } else {
                items.add(
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: StrokeCard(
                      child: ListTile(
                        title: Text(
                          c.labelCtrl.text.isEmpty
                              ? 'Untitled Question'
                              : c.labelCtrl.text,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Type: ${c.inputType} • Points: ${c.pointsCtrl.text.isEmpty ? "0" : c.pointsCtrl.text}${c.isRisk ? " • [RISK]" : ""}',
                        ),
                      ),
                    ),
                  ),
                );
              }
            }
          }

          addCriteriaWidgets(g.criteria);
          for (final sub in g.subSections) {
            if (sub.criteria.isNotEmpty) {
              items.add(
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 4.0,
                    horizontal: 16.0,
                  ),
                  child: Text(
                    sub.titleCtrl.text.isEmpty
                        ? 'Untitled Subsection'
                        : sub.titleCtrl.text,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
              );
              addCriteriaWidgets(sub.criteria);
            }
          }

          return items;
        }),
        const SizedBox(height: 16),

        // Global Risk Simulation Switch at the BOTTOM
        StrokeCard(
          child: SwitchListTile(
            key: const ValueKey('simulate_global_risk'),
            title: const Text(
              'Global Risk Override',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text('Simulate global risk failure'),
            value: _globalRisk,
            onChanged: (val) {
              setState(() {
                _globalRisk = val;
              });
            },
          ),
        ),
      ],
    );
  }
}
