# API Mock Dashboard

You are building a reporting dashboard from simulated API responses. The `files/` directory contains JSON files that simulate paginated API endpoints for a flooring business.

## Input Files

- `files/api_customers_page1.json` and `files/api_customers_page2.json` — Customer records (paginated)
- `files/api_orders.json` — All orders with customer_id references
- `files/api_products.json` — Product catalog with pricing tiers
- `files/api_config.json` — Business rules (tax rates, discount thresholds, regions)

## Tasks

### 1. Merge & Denormalize (`/task/output/orders_full.csv`)
Join orders with customers and products to create a flat CSV:
- Columns: `order_id,date,customer_name,customer_region,product_name,category,quantity,unit_price,discount_pct,subtotal,tax,total`
- Apply quantity-based discounts from config: qty >= 10 → 5%, qty >= 25 → 10%, qty >= 50 → 15%
- Tax = subtotal after discount * regional tax rate from config
- Total = discounted subtotal + tax
- Sort by date ascending

### 2. Customer Report (`/task/output/customer_report.json`)
```json
{
  "total_customers": <int>,
  "customers_with_orders": <int>,
  "customers_without_orders": <int>,
  "top_5_by_revenue": [
    {"name": "...", "total_spent": <float>, "order_count": <int>}
  ],
  "revenue_by_region": {"QC-03": <float>, "QC-06": <float>, ...},
  "avg_order_value": <float>
}
```

### 3. Product Report (`/task/output/product_report.json`)
```json
{
  "total_products": <int>,
  "units_sold_by_category": {"flooring": <int>, "coating": <int>, ...},
  "revenue_by_category": {"flooring": <float>, "coating": <float>, ...},
  "top_3_products": [
    {"name": "...", "units_sold": <int>, "revenue": <float>}
  ],
  "products_never_ordered": [<list of product names>]
}
```

### 4. Executive Summary (`/task/output/executive_summary.txt`)
A human-readable report (>300 bytes) that includes:
- Total revenue
- Number of orders
- Top customer
- Top product
- Revenue breakdown by region
- Discount impact (total discounts given)
