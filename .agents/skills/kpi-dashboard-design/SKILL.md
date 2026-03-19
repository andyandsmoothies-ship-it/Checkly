---
name: kpi-dashboard-design
description: >
  Design and build dashboards that track key performance indicators. Select
  relevant metrics, visualize data effectively, and communicate insights to
  stakeholders.
---

# KPI Dashboard Design

## When to Use

- Creating performance measurement systems
- Leadership reporting and visibility
- Operational monitoring
- Project progress tracking
- Team performance management
- Customer health monitoring
- Financial reporting

## Quick Start

Minimal working example:

```python
# Select relevant, measurable KPIs

class KPISelection:
    KPI_CRITERIA = {
        'Relevant': 'Directly aligned with business strategy',
        'Measurable': 'Can be quantified and tracked',
        'Actionable': 'Team can influence the metric',
        'Timely': 'Measured frequently (daily/weekly)',
        'Bounded': 'Has clear target/threshold',
        'Simple': 'Easy to understand'
    }

    def identify_business_goals(self):
        """Map goals to KPIs"""
        return {
            'Revenue Growth': [
                'Monthly Recurring Revenue (MRR)',
                'Annual Recurring Revenue (ARR)',
                'Customer Lifetime Value (CLV)',
                'Average Revenue Per User (ARPU)'
            ],
            'Customer Acquisition': [
                'Customer Acquisition Cost (CAC)',
                'Conversion Rate',
                'Traffic to Lead Rate',
// ... (see reference guides for full implementation)
```

## Reference Guides

Detailed implementations in the `references/` directory:

| Guide | Contents |
|---|---|
| [KPI Selection Framework](references/kpi-selection-framework.md) | KPI Selection Framework |
| [Dashboard Design](references/dashboard-design.md) | Dashboard Design |
| [Dashboard Implementation](references/dashboard-implementation.md) | Dashboard Implementation |
| [KPI Monitoring & Governance](references/kpi-monitoring-governance.md) | KPI Monitoring & Governance |
