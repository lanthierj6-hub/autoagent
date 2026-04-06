# Data Reconciliation

You have 3 data sources that partially overlap and sometimes conflict. Your job is to merge them into a single unified customer record set following specific business rules.

## Input Files
- `files/crm_customers.json` — CRM system (8 records, key: `customer_id`)
- `files/billing_data.json` — Billing system (7 records, key: `cust_id`)
- `files/activity_log.json` — Activity tracking (9 records, key: `id`)

## Business Rules for Reconciliation

### Identity Resolution
- All three sources use the same ID scheme (`NE-XXX`) but with different field names
- A customer may exist in 1, 2, or all 3 sources
- The unified record must include ALL customers from ANY source (full outer join)

### Field Priority (which source wins per field)
- **Name, email, phone, region**: CRM is authoritative. If not in CRM, leave as `"N/A"`
- **Tier**: CRM is authoritative. If not in CRM, assign based on total_invoiced: ≥50K="gold", ≥20K="silver", ≥0="bronze"
- **Financial fields** (total_invoiced, total_paid, outstanding): Billing is authoritative. If not in billing, all = 0
- **Engagement fields** (last_contact, contact_count_90d, nps_score, churn_risk): Activity is authoritative. If not in activity, set contact_count=0, nps_score=null, churn_risk="unknown"
- **payment_terms**: Billing is authoritative. Default: "net30"

### Computed Fields
- `health_score`: Calculate as: `(nps_score or 5) * 10 + contact_count_90d * 2 - (outstanding / 1000)`. Round to 1 decimal.
- `recommended_action`: Based on health_score:
  - ≥ 80: "upsell"
  - ≥ 60: "maintain"
  - ≥ 40: "nurture"
  - < 40: "rescue"
- `data_completeness`: percentage of non-null/non-default fields out of total fields (round to nearest int)

## Required Output

### `/task/output/unified_customers.csv`
Columns: `customer_id,name,email,phone,region,tier,total_invoiced,total_paid,outstanding,payment_terms,last_contact,contact_count_90d,nps_score,churn_risk,health_score,recommended_action,data_completeness`
- 10 rows (one per unique customer ID)
- Sorted by customer_id ascending

### `/task/output/reconciliation_report.json`
```json
{
  "total_unified_records": 10,
  "in_all_sources": <int>,
  "in_two_sources": <int>,
  "in_one_source": <int>,
  "total_outstanding": <float>,
  "avg_health_score": <float>,
  "action_distribution": {"upsell": <int>, "maintain": <int>, "nurture": <int>, "rescue": <int>},
  "highest_risk_customer": "<customer_id with lowest health_score>",
  "top_customer_by_revenue": "<customer_id with highest total_invoiced>"
}
```
