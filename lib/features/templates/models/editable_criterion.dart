import 'dart:convert';

import 'package:flutter/material.dart';

import './template_dto.dart';

class EditableCriterion {
  final String id;
  final TextEditingController labelCtrl;
  final TextEditingController descCtrl;
  final TextEditingController pointsCtrl;
  final TextEditingController minusImpactCtrl;
  final TextEditingController maxDeductionCtrl;
  String inputType;
  List<Map<String, dynamic>> scaleOptions;
  List<String> choiceOptions;
  bool isCcp;
  bool isRisk;
  bool isRequired;

  EditableCriterion({
    this.id = '',
    String label = '',
    String description = '',
    String points = '',
    String minusImpact = '',
    String maxDeduction = '',
    this.inputType = 'numeric',
    List<Map<String, dynamic>>? scaleOptions,
    List<String>? choiceOptions,
    this.isCcp = false,
    this.isRisk = false,
    this.isRequired = false,
  }) : labelCtrl = TextEditingController(text: label),
       descCtrl = TextEditingController(text: description),
       pointsCtrl = TextEditingController(text: points),
       minusImpactCtrl = TextEditingController(text: minusImpact),
       maxDeductionCtrl = TextEditingController(text: maxDeduction),
       scaleOptions = scaleOptions ?? [],
       choiceOptions = choiceOptions ?? [];

  factory EditableCriterion.fromDto(CriterionDto dto) {
    List<Map<String, dynamic>> options = [];
    List<String> choices = [];
    bool isRequired = false;

    if (dto.metadata != null) {
      try {
        final meta = json.decode(dto.metadata!) as Map<String, dynamic>;
        isRequired = meta['isRequired'] == true;

        if (dto.inputType == 'scale') {
          options =
              (meta['scaleOptions'] as List?)
                  ?.map((e) => Map<String, dynamic>.from(e as Map))
                  .toList() ??
              [];
        } else if (dto.inputType == 'single_choice' ||
            dto.inputType == 'multi_choice') {
          choices =
              (meta['options'] as List?)?.map((e) {
                if (e is String) return e;
                if (e is Map) return (e['label'] as String?) ?? '';
                return e.toString();
              }).toList() ??
              [];
        }
      } catch (e) {
        debugPrint('Criterion metadata parse: $e');
      }
    }

    return EditableCriterion(
      id: dto.id,
      label: dto.label,
      description: dto.description ?? '',
      points: dto.pointsWeight?.toString() ?? '',
      minusImpact: dto.minusImpact?.toString() ?? '',
      maxDeduction: dto.maxDeductionPoints?.toString() ?? '',
      inputType: dto.inputType,
      scaleOptions: options,
      choiceOptions: choices,
      isCcp: dto.isCcp,
      isRisk: dto.isRisk,
      isRequired: isRequired,
    );
  }

  void dispose() {
    labelCtrl.dispose();
    descCtrl.dispose();
    pointsCtrl.dispose();
    minusImpactCtrl.dispose();
    maxDeductionCtrl.dispose();
  }
}
