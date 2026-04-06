"""Main orchestrator for the lead scoring pipeline."""
import json
import os
import sys

# BUG 10: wrong import path - should import from app package
from app import ScoreEngine, Lead, Pipeline


def load_leads(filepath: str) -> list:
    """Load leads from JSON file."""
    with open(filepath) as f:
        data = json.load(f)

    leads = []
    for item in data:
        lead = Lead(
            name=item["name"],
            email=item["email"],
            company=item["company"],
            title=item["title"],
            region=item["region"],
            budget=float(item["budget"]),
            interest_level=int(item["interest_level"]),
            source=item["source"],
        )
        leads.append(lead)
    return leads


def run_pipeline():
    """Run the full scoring pipeline."""
    input_path = "/task/files/leads_input.json"
    output_dir = "/task/output"
    os.makedirs(output_dir, exist_ok=True)

    # Load leads
    leads = load_leads(input_path)

    # Initialize
    engine = ScoreEngine()
    pipeline = Pipeline(leads=leads)

    # Score all leads
    for lead in leads:
        score = engine.score_lead(lead)
        pipeline.scores.append(score)

    # Build scored leads output
    scored_leads = []
    for lead, score in zip(leads, pipeline.scores):
        scored_leads.append({
            "name": lead.name,
            "email": lead.email,
            "company": lead.company,
            "title": lead.title,
            "region": lead.region,
            "budget": lead.budget,
            "interest_level": lead.interest_level,
            "source": lead.source,
            "score": score.raw_score,
            "grade": score.grade,
            "qualified": score.qualified,
        })

    # Sort by score descending
    scored_leads.sort(key=lambda x: x["score"], reverse=True)

    # Write outputs
    with open(os.path.join(output_dir, "scored_leads.json"), "w") as f:
        json.dump(scored_leads, f, indent=2)

    stats = {
        "total_leads": len(leads),
        "qualified_count": len(pipeline.qualified_leads),
        "disqualified_count": len(leads) - len(pipeline.qualified_leads),
        "avg_score": round(pipeline.avg_score, 1),
        "grade_distribution": pipeline.grade_distribution(),
        "top_lead": scored_leads[0]["name"] if scored_leads else None,
    }

    with open(os.path.join(output_dir, "pipeline_stats.json"), "w") as f:
        json.dump(stats, f, indent=2)

    print(f"Pipeline complete: {len(leads)} leads scored")
    print(f"Qualified: {stats['qualified_count']}, Average: {stats['avg_score']}")


if __name__ == "__main__":
    run_pipeline()
