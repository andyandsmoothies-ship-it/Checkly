import 'package:flutter/material.dart';

class WizardNavigationBar extends StatelessWidget {
  final int currentStep;
  final bool isSaving;
  final bool templateIsValid;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onSave;

  const WizardNavigationBar({
    super.key,
    required this.currentStep,
    required this.isSaving,
    required this.templateIsValid,
    required this.onPrev,
    required this.onNext,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        child: Row(
          children: [
            if (currentStep > 0)
              OutlinedButton(
                onPressed: isSaving ? null : onPrev,
                child: const Text('Back'),
              ),
            const Spacer(),
            FilledButton(
              onPressed: (isSaving || (currentStep == 3 && !templateIsValid))
                  ? null
                  : () {
                      if (currentStep == 3) {
                        onSave();
                      } else {
                        onNext();
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(currentStep == 3 ? 'Save Template' : 'Next'),
            ),
          ],
        ),
      ),
    );
  }
}
