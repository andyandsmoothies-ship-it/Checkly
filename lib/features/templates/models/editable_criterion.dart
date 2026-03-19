import 'dart:convert';

import 'package:flutter/material.dart';

import '../model/template_dto.dart';

class EditableCriterion {
  final String id;
  final TextEditingController labelCtrl;
  final TextEditingController descCtrl;
  final TextEditingController pointsCtrl;
  String inputType;
  List<Map<String, dynamic>> scaleOptions;
  List<String> choiceOptions;

  EditableCriterion({
    this.id = '',
    String label = '',
    String description = '',
    String points = '',
    this.inputType = 'numeric',
    List<Map<String, dynamic>>? scaleOptions,
    List<String>? choiceOptions,
  }) : labelCtrl = TextEditingController(text: label),
       descCtrl = TextEditingController(text: description),
       pointsCtrl = TextEditingController(text: points),
       scaleOptions = scaleOptions ?? [],
       choiceOptions = choiceOptions ?? [];

  factory EditableCriterion.fromDto(CriterionDto dto) {
    List<Map<String, dynamic>> options = [];
    List<String> choices = [];
    if (dto.metadata != null && dto.inputType == 'scale') {
      try {
        final meta = json.decode(dto.metadata!) as Map<String, dynamic>;
        options =
            (meta['scaleOptions'] as List?)
                ?.map((e) => Map<String, dynamic>.from(e as Map))
                .toList() ??
            [];
      } catch (e) {
        debugPrint('Criterion metadata parse: $e');
      }
    } else if (dto.metadata != null &&
        (dto.inputType == 'single_choice' || dto.inputType == 'multi_choice')) {
      try {
        final meta = json.decode(dto.metadata!) as Map<String, dynamic>;
        choices = (meta['options'] as List?)?.cast<String>() ?? [];
      } catch (e) {
        debugPrint('Criterion metadata parse: $e');
      }
    }
    return EditableCriterion(
      id: dto.id,
      label: dto.label,
      description: dto.description ?? '',
      points: dto.pointsWeight?.toString() ?? '',
      inputType: dto.inputType,
      scaleOptions: options,
      choiceOptions: choices,
    );
  }

  void dispose() {
    labelCtrl.dispose();
    descCtrl.dispose();
    pointsCtrl.dispose();
  }
}
