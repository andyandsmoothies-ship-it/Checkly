# Executed Tests: TemplateManager and AnalyticsManager
## Input Lineage
- **Source Input**: `c:\Users\HP\Documents\GitHub\Checkly\.agents\active_tasks\audit-code\task_20260508_191800_4cf3f41a_audit-code-verify.md`

## Terminal Output
```
00:00 +0: loading C:/Users/HP/Documents/GitHub/Checkly/test/features/templates/manager/template_manager_test.dart
00:00 +0: TemplateManager Tests loadTemplates uses cache first, then API
00:00 +1: TemplateManager Tests loadTemplates handles offline gracefully if cache exists
00:00 +2: TemplateManager Tests loadTemplates sets error if API fails and cache is empty
00:00 +3: TemplateManager Tests loadTemplateTree uses cache first, then API
00:00 +4: TemplateManager Tests deleteTemplate updates API and local state
00:00 +5: All tests passed!

00:00 +0: loading C:/Users/HP/Documents/GitHub/Checkly/test/features/analytics/manager/analytics_manager_test.dart
00:00 +0: AnalyticsManager computes basic KPIs from empty DB
00:00 +1: AnalyticsManager computes KPIs accurately from populated DB
00:00 +2: AnalyticsManager applies filters correctly
00:00 +3: All tests passed!
```

<test_trace>
00:00 +0: loading C:/Users/HP/Documents/GitHub/Checkly/test/features/templates/manager/template_manager_test.dart
00:00 +0: TemplateManager Tests loadTemplates uses cache first, then API
00:00 +1: TemplateManager Tests loadTemplates handles offline gracefully if cache exists
00:00 +2: TemplateManager Tests loadTemplates sets error if API fails and cache is empty
00:00 +3: TemplateManager Tests loadTemplateTree uses cache first, then API
00:00 +4: TemplateManager Tests deleteTemplate updates API and local state
00:00 +5: All tests passed!

00:00 +0: loading C:/Users/HP/Documents/GitHub/Checkly/test/features/analytics/manager/analytics_manager_test.dart
00:00 +0: AnalyticsManager computes basic KPIs from empty DB
00:00 +1: AnalyticsManager computes KPIs accurately from populated DB
00:00 +2: AnalyticsManager applies filters correctly
00:00 +3: All tests passed!
</test_trace>

<forensic_evidence>
Ran `flutter test test/features/analytics/manager/analytics_manager_test.dart`
</forensic_evidence>
