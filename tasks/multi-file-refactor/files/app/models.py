"""Data models for the lead scoring system."""
from dataclasses import dataclass, field
from typing import Optional


@dataclass
class Lead:
    name: str
    email: str
    company: str
    title: str
    region: str
    budget: float
    interest_level: int  # 1-10
    source: str

    # BUG 2: property should check interest_level >= 7 not > 7
    @property
    def is_high_interest(self) -> bool:
        return self.interest_level > 7


@dataclass
class Score:
    lead_name: str
    raw_score: float
    grade: str
    qualified: bool

    # BUG 3: Grade boundaries are wrong (should be >=90=A, >=75=B, >=60=C, >=40=D, else F)
    @staticmethod
    def calculate_grade(score: float) -> str:
        if score >= 90:
            return "A"
        elif score >= 80:  # Should be 75
            return "B"
        elif score >= 70:  # Should be 60
            return "C"
        elif score >= 50:  # Should be 40
            return "D"
        else:
            return "F"


@dataclass
class Pipeline:
    leads: list = field(default_factory=list)
    scores: list = field(default_factory=list)

    @property
    def qualified_leads(self):
        return [s for s in self.scores if s.qualified]

    @property
    def avg_score(self):
        if not self.scores:
            return 0
        # BUG 4: Uses len(self.leads) instead of len(self.scores)
        return sum(s.raw_score for s in self.scores) / len(self.leads)

    def grade_distribution(self):
        dist = {"A": 0, "B": 0, "C": 0, "D": 0, "F": 0}
        for s in self.scores:
            dist[s.grade] += 1
        return dist
