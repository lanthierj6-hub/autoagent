"""Test suite for the pricing engine. The implementation must pass ALL tests."""
import sys
import os
sys.path.insert(0, "/task/output")

import pytest
from decimal import Decimal
from pricing_engine import (
    PricingEngine,
    Product,
    Customer,
    LineItem,
    Invoice,
    DiscountType,
    TaxRegion,
)


# ── Product creation ──

def test_product_creation():
    p = Product(sku="EP-001", name="Epoxy Standard", base_price=Decimal("89.99"), category="flooring")
    assert p.sku == "EP-001"
    assert p.base_price == Decimal("89.99")


def test_product_with_zero_price_raises():
    with pytest.raises(ValueError):
        Product(sku="X", name="X", base_price=Decimal("0"), category="x")


def test_product_with_negative_price_raises():
    with pytest.raises(ValueError):
        Product(sku="X", name="X", base_price=Decimal("-10"), category="x")


# ── Customer tiers ──

def test_customer_tier_gold():
    c = Customer(customer_id="C001", name="Test", tier="gold", region=TaxRegion.QUEBEC)
    assert c.tier_discount == Decimal("0.10")


def test_customer_tier_silver():
    c = Customer(customer_id="C002", name="Test", tier="silver", region=TaxRegion.QUEBEC)
    assert c.tier_discount == Decimal("0.05")


def test_customer_tier_bronze():
    c = Customer(customer_id="C003", name="Test", tier="bronze", region=TaxRegion.QUEBEC)
    assert c.tier_discount == Decimal("0.00")


def test_customer_invalid_tier_raises():
    with pytest.raises(ValueError):
        Customer(customer_id="C999", name="Test", tier="platinum", region=TaxRegion.QUEBEC)


# ── Tax regions ──

def test_tax_quebec():
    assert TaxRegion.QUEBEC.rate == Decimal("0.14975")


def test_tax_ontario():
    assert TaxRegion.ONTARIO.rate == Decimal("0.13")


def test_tax_alberta():
    assert TaxRegion.ALBERTA.rate == Decimal("0.05")


# ── Line item calculations ──

def test_line_item_subtotal():
    p = Product(sku="EP-001", name="Epoxy", base_price=Decimal("100.00"), category="flooring")
    li = LineItem(product=p, quantity=5)
    assert li.subtotal == Decimal("500.00")


def test_line_item_zero_quantity_raises():
    p = Product(sku="EP-001", name="Epoxy", base_price=Decimal("100.00"), category="flooring")
    with pytest.raises(ValueError):
        LineItem(product=p, quantity=0)


# ── Discount types ──

def test_volume_discount_under_threshold():
    assert DiscountType.volume_discount(5) == Decimal("0.00")


def test_volume_discount_10_plus():
    assert DiscountType.volume_discount(10) == Decimal("0.05")


def test_volume_discount_25_plus():
    assert DiscountType.volume_discount(25) == Decimal("0.10")


def test_volume_discount_50_plus():
    assert DiscountType.volume_discount(50) == Decimal("0.15")


def test_volume_discount_100_plus():
    assert DiscountType.volume_discount(100) == Decimal("0.20")


# ── Invoice generation ──

@pytest.fixture
def engine():
    return PricingEngine()


@pytest.fixture
def sample_product():
    return Product(sku="EP-001", name="Epoxy Standard", base_price=Decimal("100.00"), category="flooring")


@pytest.fixture
def gold_customer():
    return Customer(customer_id="C001", name="Gold Corp", tier="gold", region=TaxRegion.QUEBEC)


def test_invoice_single_item(engine, sample_product, gold_customer):
    items = [LineItem(product=sample_product, quantity=5)]
    invoice = engine.generate_invoice(gold_customer, items)
    assert isinstance(invoice, Invoice)
    assert invoice.customer_id == "C001"
    assert len(invoice.lines) == 1


def test_invoice_applies_tier_discount(engine, sample_product, gold_customer):
    """Gold tier gets 10% off subtotal before tax."""
    items = [LineItem(product=sample_product, quantity=10)]
    invoice = engine.generate_invoice(gold_customer, items)
    # subtotal = 1000, volume disc = 5% -> 950, tier disc = 10% -> 855
    assert invoice.subtotal_after_discounts == Decimal("855.00")


def test_invoice_applies_volume_and_tier_discount(engine, sample_product, gold_customer):
    """Volume discount applied first, then tier discount."""
    items = [LineItem(product=sample_product, quantity=50)]
    invoice = engine.generate_invoice(gold_customer, items)
    # subtotal=5000, volume=15%->4250, tier=10%->3825
    assert invoice.subtotal_after_discounts == Decimal("3825.00")


def test_invoice_tax_calculation(engine, sample_product, gold_customer):
    """Tax is calculated on subtotal_after_discounts."""
    items = [LineItem(product=sample_product, quantity=10)]
    invoice = engine.generate_invoice(gold_customer, items)
    # subtotal_after_discounts=855, tax=855*0.14975
    expected_tax = (Decimal("855.00") * Decimal("0.14975")).quantize(Decimal("0.01"))
    assert invoice.tax == expected_tax


def test_invoice_total(engine, sample_product, gold_customer):
    """Total = subtotal_after_discounts + tax."""
    items = [LineItem(product=sample_product, quantity=10)]
    invoice = engine.generate_invoice(gold_customer, items)
    assert invoice.total == invoice.subtotal_after_discounts + invoice.tax


def test_invoice_multi_item(engine, gold_customer):
    """Invoice with multiple different products."""
    p1 = Product(sku="EP-001", name="Epoxy", base_price=Decimal("100.00"), category="flooring")
    p2 = Product(sku="PC-002", name="Coating", base_price=Decimal("200.00"), category="coating")
    items = [LineItem(product=p1, quantity=5), LineItem(product=p2, quantity=3)]
    invoice = engine.generate_invoice(gold_customer, items)
    # p1: 500, p2: 600, total subtotal: 1100
    # Volume discounts per line: p1 qty5->0%, p2 qty3->0%
    # After volume: 1100, tier 10%: 990
    assert invoice.subtotal_after_discounts == Decimal("990.00")
