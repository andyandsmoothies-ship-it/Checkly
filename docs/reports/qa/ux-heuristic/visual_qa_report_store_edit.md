# Visual QA Report: Store Edit Chunk

## Objective
Evaluate the deployed visual rendering of the Store Edit module based on the provided screenshot, focusing on proportion, whitespace harmony, and accessibility rendering.

## Step 2: Visual Inspection
From the visual evidence, I observe:
- **Background & Color Boundary Issue**: The bottom sheet has a warm beige/off-white background. The text fields have a `filled: true` white background. Because of this, the floating labels (e.g., "Store Name *", "Address", "Province") straddle the boundary between the white interior and the beige exterior. This creates a harsh horizontal visual cut through the labels.
- **Spacing and Counter Cramping**: The `maxLength` character counters ("0/100", "0/200") for the District, Ward, and Street fields are severely cramped. They are floating immediately above the next input field with almost zero padding, breaking visual hierarchy.
- **Inconsistent Labeling**: Some fields have floating labels because they contain text, while empty fields (District, Ward, Street) show the label resting inside as a placeholder. When they float, they will also suffer from the color boundary issue.
- **Horizontal Cramping**: The Latitude and Longitude fields are placed side-by-side but feel compressed.
- **Map Aesthetics**: The map widget at the bottom has rounded corners but lacks a distinct visual container or subtle border, making it feel slightly detached from the premium UI language.

## Step 3: Diagnostic Mapping
- **File**: `lib/features/admin/pages/widgets/store_form_body.dart`
- **Root Causes**:
  - The use of default `OutlineInputBorder` combined with a white fill color on a non-white background causes the floating label visual glitch.
  - The `SizedBox(height: 4)` after District and Ward fields is drastically too small to accommodate the built-in `maxLength` counter text.
  - The default floating label behavior (`FloatingLabelBehavior.auto`) causes the inconsistent label positioning depending on whether the field is empty.

## Step 4: Remediation Plan
1. **Fix Spacing**: Increase the vertical spacing between the `maxLength` fields. Change `SizedBox(height: 4)` to at least `SizedBox(height: 16)` or `20` to allow the character counter room to breathe.
2. **Resolve Floating Label Glitch**: 
   - Option A: Change `floatingLabelBehavior: FloatingLabelBehavior.always` so it's consistent, and wrap the fields in a `Theme` that sets the `canvasColor` or `scaffoldBackgroundColor` to match the sheet, or just let the label have a white background.
   - Option B (Premium): Move the labels **outside** the text fields as distinct `Text` widgets (e.g., small, bold, dark grey) above each field, and set `floatingLabelBehavior: FloatingLabelBehavior.never`. This eliminates the border intersection issue entirely and provides a clean, modern "Duolingo/Premium" look.
3. **Map Container**: Wrap the `StoreLocationMapWidget` in a premium card or container with a subtle inner shadow or precise border to integrate it better with the form.

## Conclusion
The current rendering partially achieves a modern look but suffers from claustrophobic padding and default Material border glitches. Implementing the remediation plan will align this screen with the intended premium aesthetic.
