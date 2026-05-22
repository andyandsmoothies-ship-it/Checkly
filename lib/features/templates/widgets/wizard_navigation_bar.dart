import 'package:flutter/material.dart';
import '../../../_shared/theme/app_colors.dart';
import '../../../_shared/widgets/primitives/bubbly_button.dart';

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
    final isNextEnabled = !(isSaving || (currentStep == 3 && !templateIsValid));

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        child: Row(
          children: [
            if (currentStep > 0)
              SizedBox(
                width: 100,
                height: 48,
                child: BubblyButton(
                  label: 'Back',
                  color: AppColors.swan,
                  textColor: AppColors.wolf,
                  onPressed: isSaving ? null : onPrev,
                ),
              ),
            const Spacer(),
            SizedBox(
              width: 160,
              height: 48,
              child: BubblyButton(
                label: currentStep == 3 ? 'Save' : 'Next',
                isLoading: isSaving,
                color: isNextEnabled ? AppColors.featherGreen : AppColors.swan,
                textColor: isNextEnabled ? Colors.white : AppColors.wolf,
                onPressed: isNextEnabled
                    ? () {
                        if (currentStep == 3) {
                          onSave();
                        } else {
                          onNext();
                        }
                      }
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
