#!/usr/bin/env python3
"""ETL Pipeline for sales data - CONTAINS DELIBERATE BUGS"""
import json
import csv
import os
# BUG 1: missing import (datetime is needed but not imported)

OUTPUT_DIR = "/task/output"
INPUT_FILE = "/task/files/sales_raw.json"
TAX_RATE = 0.14975

def load_data(filepath):
    with open(filepath, "r") as f:
        return json.load(f)

def validate_record(record):
    """Return True if record is valid, False otherwise."""
    # BUG 2: wrong variable name (uses 'quantity' instead of 'qty')
    if record.get("quantity", 0) <= 0:
        return False
    try:
        from datetime import datetime
        datetime.strptime(record["date"], "%Y-%m-%d")
    except (ValueError, KeyError):
        return False
    return True

def deduplicate(records):
    """Remove exact duplicates based on date+product+region."""
    seen = set()
    unique = []
    for r in records:
        # BUG 3: logic error - key should include qty+price for exact dedup, but also
        # the real bug is that it APPENDS to seen BEFORE checking, so first item is skipped
        key = (r["date"], r["product"], r["region"])
        seen.add(key)
        if key not in seen:
            unique.append(r)
    return unique

def transform(records):
    """Calculate totals and tax for each record."""
    results = []
    for r in records:
        qty = r["qty"]
        price = r["price"]
        total = qty * price
        # BUG 4: tax formula is wrong (multiplies by tax_rate squared)
        tax = total * TAX_RATE * TAX_RATE
        grand_total = total + tax
        results.append({
            "date": r["date"],
            "product": r["product"],
            "region": r["region"],
            "quantity": qty,
            "unit_price": price,
            "total": round(total, 2),
            "tax": round(tax, 2),
            "grand_total": round(grand_total, 2)
        })
    # BUG 5: sorts by product instead of date
    results.sort(key=lambda x: x["product"])
    return results

def write_csv(records, filepath):
    os.makedirs(os.path.dirname(filepath), exist_ok=True)
    fields = ["date", "product", "region", "quantity", "unit_price", "total", "tax", "grand_total"]
    with open(filepath, "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fields)
        writer.writeheader()
        # BUG 6: off-by-one, skips the first record
        for row in records[1:]:
            writer.writerow(row)

def write_summary(records, rejected_count, filepath):
    total_rev = sum(r["grand_total"] for r in records)
    product_rev = {}
    for r in records:
        product_rev[r["product"]] = product_rev.get(r["product"], 0) + r["grand_total"]
    top = max(product_rev, key=product_rev.get)
    summary = {
        "total_revenue": round(total_rev, 2),
        "top_product": top,
        "records_processed": len(records),
        "records_rejected": rejected_count,
        "avg_order_value": round(total_rev / len(records), 2)
    }
    with open(filepath, "w") as f:
        json.dump(summary, f, indent=2)

def main():
    raw = load_data(INPUT_FILE)
    deduped = deduplicate(raw)
    valid = [r for r in deduped if validate_record(r)]
    rejected = len(raw) - len(valid)
    transformed = transform(valid)
    write_csv(transformed, os.path.join(OUTPUT_DIR, "sales_clean.csv"))
    write_summary(transformed, rejected, os.path.join(OUTPUT_DIR, "summary.json"))
    print(f"ETL complete: {len(transformed)} records written, {rejected} rejected")

if __name__ == "__main__":
    main()
