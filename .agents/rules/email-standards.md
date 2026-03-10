---
name: ToolKit.VoucherSender Email Standards
description: Best practices for SMTP delivery using MailKit and MimeKit. Applies ONLY when modifying ToolKit.VoucherSender.
trigger: manual
---

# Rule: VoucherSender Email Standards

This rule applies whenever modifying `EmailService` or SMTP configuration logic.

## 1. Library Selection
- **MailKit/MimeKit**: Use exclusively. NEVER use `System.Net.Mail` (obsolete/deprecated).

## 2. SMTP Protocol
- **STARTTLS**: Default on port 587.
- **Authentication**: Credentials are provided per-session via UI and held in `SendSessionState`. DO NOT store credentials in `appsettings.json` in production.

## 3. Delivery Patterns
- **Rate Limiting**: Add a minimum `Task.Delay(1000)` between sending emails in a batch to avoid Outlook rate limit bans.
- **Templates**: Support HTML bodies with these placeholders:
  - `{EmployeeName}`
  - `{VoucherCount}`
  - `{VoucherList}` (rendered as a list or table)
- **Validation**: Verify the "From" address matches the authenticated SMTP username.
