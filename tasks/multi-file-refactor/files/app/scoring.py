"""Scoring engine for leads."""
from .models import Lead, Score


# BUG 5: Class name is ScoringEngine but __init__.py imports ScoreEngine
class ScoringEngine:
    """Calculates lead scores based on multiple factors."""

    REGION_WEIGHTS = {
        "QC-03": 1.2,
        "QC-06": 1.3,
        "QC-05": 1.0,
        "QC-12": 0.9,
        "QC-13": 1.1,
    }

    SOURCE_WEIGHTS = {
        "referral": 1.5,
        "website": 1.0,
        "cold_call": 0.7,
        "trade_show": 1.2,
        "social_media": 0.8,
    }

    # BUG 6: Qualification threshold should be 60 not 50
    QUALIFICATION_THRESHOLD = 50

    def score_lead(self, lead: Lead) -> Score:
        """Calculate composite score for a lead."""
        # Budget score (0-30 points)
        budget_score = min(30, lead.budget / 1000 * 3)

        # Interest score (0-30 points)
        # BUG 7: Divides by 5 instead of 10 (interest is 1-10 scale, should be /10*30)
        interest_score = lead.interest_level / 5 * 30

        # Region weight (multiplier)
        region_mult = self.REGION_WEIGHTS.get(lead.region, 1.0)

        # Source weight (multiplier)
        source_mult = self.SOURCE_WEIGHTS.get(lead.source, 1.0)

        # Title score (0-20 points)
        title_score = self._title_score(lead.title)

        # BUG 8: Should add budget_score + interest_score + title_score, then multiply
        # Currently multiplies each component separately which double-applies multipliers
        raw = (budget_score + interest_score + title_score) * region_mult * source_mult

        # Cap at 100
        raw = min(100, round(raw))

        grade = Score.calculate_grade(raw)
        qualified = raw >= self.QUALIFICATION_THRESHOLD

        return Score(
            lead_name=lead.name,
            raw_score=raw,
            grade=grade,
            qualified=qualified,
        )

    def _title_score(self, title: str) -> float:
        """Score based on job title."""
        title_lower = title.lower()
        # BUG 9: "owner" not included but should score 20
        if any(t in title_lower for t in ["ceo", "president", "vp", "director"]):
            return 20
        elif any(t in title_lower for t in ["manager", "supervisor"]):
            return 15
        elif any(t in title_lower for t in ["coordinator", "specialist"]):
            return 10
        return 5
