---
name: ToolKit.VoucherSender Excel Handling
description: Rules for the unified Excel voucher format using ClosedXML. Applies ONLY when modifying ToolKit.VoucherSender.
trigger: manual
---

# Rule: VoucherSender Excel Handling

This rule applies whenever implementing or modifying Excel-related logic or the `ExcelReaderService`.

## 1. Unified File Format
The project uses a single Excel file with these mandatory columns:
- Program Code
- Program Name
- Voucher Code
- Start Date
- End Date
- Email
- Employee Name

## 2. Implementation Patterns
- **Header Detection**: Detection must be by column name string, not hardcoded index.
- **Data Types**: Excel stores numbers as `double`. Use `double.TryParse` fallback if `int.TryParse` fails for voucher codes.
- **Magic Bytes**: Always verify the ZIP signature (`0x50 0x4B 0x03 0x04`) before parsing as `.xlsx`.

## 3. Performance & Limits
- **Row Limit**: Hard cap at 5,000 rows.
- **File Size**: 50MB maximum (to prevent 500MB+ RAM usage).
- **Scanning**: Stop reading at the first completely empty row.
