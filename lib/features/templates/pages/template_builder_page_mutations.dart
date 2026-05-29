// ignore_for_file: invalid_use_of_protected_member
part of 'template_builder_page.dart';

extension _TemplateBuilderMutations on _TemplateBuilderPageState {
  // ── Section/Criteria mutation helpers ──
  void _addSection() {
    setState(() {
      _sections.add(EditableGroup());
      _isDirty = true;
    });
    _triggerLinter();
  }

  void _removeSection(int index) {
    setState(() {
      _sections[index].dispose();
      _sections.removeAt(index);
      _isDirty = true;
    });
    _triggerLinter();
  }

  void _addSubSection(int sectionIndex) {
    setState(() {
      _sections[sectionIndex].subSections.add(EditableGroup());
      _isDirty = true;
    });
    _triggerLinter();
  }

  void _removeSubSection(int sectionIndex, int subIndex) {
    setState(() {
      _sections[sectionIndex].subSections[subIndex].dispose();
      _sections[sectionIndex].subSections.removeAt(subIndex);
      _isDirty = true;
    });
    _triggerLinter();
  }

  void _addCriterionToGroup(
    EditableGroup group, [
    String inputType = 'pass_fail',
  ]) {
    setState(() {
      group.criteria.add(EditableCriterion(inputType: inputType));
      _isDirty = true;
    });
    _triggerLinter();
  }

  void _removeCriterionFromGroup(EditableGroup group, int criterionIndex) {
    final c = group.criteria[criterionIndex];
    setState(() {
      c.dispose();
      group.criteria.removeAt(criterionIndex);
      _isDirty = true;
    });
    _triggerLinter();
  }

  // ── Computed values ──
  int get _totalPoints {
    int sumMaxPoints(List<EditableGroup> groups) {
      var pts = 0;
      for (final g in groups) {
        // Sum criteria directly attached to this group
        for (final c in g.criteria) {
          if (c.inputType != 'text' &&
              c.inputType != 'single_choice' &&
              c.inputType != 'multi_choice') {
            pts += (double.tryParse(c.pointsCtrl.text) ?? 0).toInt();
          }
        }
        // Add recursive sub-sections
        pts += sumMaxPoints(g.subSections);
      }
      return pts;
    }

    return sumMaxPoints(_sections);
  }

  double get _totalDensity {
    var d = 0.0;
    for (final s in _sections) {
      d += double.tryParse(s.weightCtrl.text) ?? 0;
    }
    return d;
  }
}
