/// Converts a raw templateType value (e.g. 'food_safety') to a
/// display-friendly label (e.g. 'Food Safety').
String formatCategory(String type) =>
    type.split('_').map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
