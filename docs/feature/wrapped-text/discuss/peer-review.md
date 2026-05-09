# Peer Review: wrapped-text User Stories

```yaml
review_id: "req_rev_20260509_001"
reviewer: "product-owner (review mode)"
artifact: "docs/feature/wrapped-text/discuss/user-stories.md"
iteration: 1

strengths:
  - "All three stories include Elevator Pitch sections with concrete Before/After/Decision-enabled lines"
  - "Domain examples use a named persona (Riku Nakamura) with specific data (fontSize 14, maxWidth 200, 47-word description)"
  - "UAT scenarios are written in Given/When/Then with concrete values; no abstract 'user' references"
  - "Technical notes are solution-aware but solution-neutral at the requirements level (no Swift implementation prescribed)"
  - "Outcome KPIs follow Gothelf/Seiden formula (Who/Does What/By How Much/Measured By/Baseline)"
  - "System Constraints section at top correctly captures cross-cutting constraints"
  - "Open design question (line-string access) is explicitly flagged rather than silently resolved"
  - "US-02 correctly addresses the riskiest technical failure mode (infinite loop from unbreakable word)"

issues_identified:
  confirmation_bias:
    - issue: "Happy path bias: US-01 has no scenario covering a text that is exactly maxWidth wide (boundary condition where no wrap should occur)"
      severity: "medium"
      location: "US-01 UAT Scenarios"
      recommendation: "Add scenario: 'Given content that measures exactly maxWidth width, Then no line break occurs and exactly 1 child is produced'. Already partially covered by Example 3 (Go now.) but not expressed as a BDD scenario."
    - issue: "US-01 has no scenario for multi-word content where the first word alone would fit but adding any second word exceeds maxWidth — tests the line-break-before-append path specifically"
      severity: "low"
      location: "US-01 UAT Scenarios"
      recommendation: "Consider adding: 'Given first word = 180px, second word = 50px, maxWidth = 200, Then 2 children produced (each word on own line)'. Low priority — covered implicitly by multi-line scenario."

  completeness_gaps:
    - issue: "US-03 has only 3 UAT scenarios — minimum is 3 so this passes DoR, but the scenario for 'empty WrappedText in renderer' (Example 3) is described in domain examples but not expressed as a BDD scenario"
      severity: "low"
      location: "US-03 UAT Scenarios"
      recommendation: "Consider promoting Example 3 (empty content → 0 draw calls, no crash) to a named BDD scenario. DoR still passes at 3."
    - issue: "No NFR on layout determinism stated explicitly in US-01 or US-02 (though mentioned in system constraints and outcome-kpis.md guardrails)"
      severity: "low"
      location: "US-01 Acceptance Criteria"
      recommendation: "Add AC: 'Given identical content, fontSize, color, and LayoutConstraints, LayoutEngine.layout returns identical LayoutTree across multiple calls.' This is testable and guards against accidental stateful behaviour."

  clarity_issues:
    - issue: "US-03 Acceptance Criteria item 1 says 'or equivalent resolved approach' — this conditional language makes it ambiguous what the tester must verify"
      severity: "medium"
      location: "US-03 Acceptance Criteria item 1"
      recommendation: "Remove 'or equivalent resolved approach'. AC must be unambiguous. Change to: 'WrappedText exposes a lines: [String] property populated during LayoutEngine layout.' If the design decision changes to Option C, this AC gets updated before handoff. Flag as pending design decision explicitly."
    - issue: "US-01 AC item 'Root node frame.size.width == constraints.maxWidth' — this may not hold when content is shorter than maxWidth on a single line. The root should probably be min(longestLineWidth, maxWidth) or always maxWidth. Needs clarification."
      severity: "high"
      location: "US-01 Acceptance Criteria"
      recommendation: "Clarify: does root frame width equal constraints.maxWidth always, or is it the width of the longest child? This is a design decision. Recommend: root frame width = constraints.maxWidth (consistent with container behaviour documented in Technical Notes). Make AC conditional explicit: 'Root node frame.size.width == constraints.maxWidth (root fills available width, consistent with container behaviour)'."

  testability_concerns:
    - issue: "US-03 scenario 'README example covers WrappedText renderer integration' is not automatically testable — it is a documentation review criterion"
      severity: "low"
      location: "US-03 Scenario 1"
      recommendation: "This is acceptable for documentation stories. Add note: '(Manual review AC — verified by code reviewer during PR)'. The other two US-03 scenarios are fully automatable."

  priority_validation:
    q1_largest_bottleneck: "YES — manual line-break computation is the stated pain; WrappedText directly eliminates it"
    q2_simple_alternatives: "ADEQUATE — VStack+Text workaround documented as baseline; WrappedText is clearly the minimal right solution"
    q3_constraint_prioritization: "CORRECT — Slice 1 (core) → Slice 2 (robustness) → Slice 3 (documentation) is the right order"
    q4_data_justified: "JUSTIFIED — char-count fallback matches existing Text node behaviour; greedy algorithm is the standard word-wrap approach"
    verdict: "PASS"

approval_status: "conditionally_approved"
critical_issues_count: 0
high_issues_count: 1
medium_issues_count: 2
low_issues_count: 3
```

## Required Remediations Before Final Approval

### HIGH — Clarify root frame width behaviour (US-01 AC)

The AC states "Root node `frame.size.width == constraints.maxWidth`" without qualification. This is ambiguous when content fits on one line shorter than `maxWidth`. Recommend making the design decision explicit in the AC:

> "Root node `frame.size.width == constraints.maxWidth` (root always fills available width, consistent with container behaviour)"

This aligns with the Technical Notes and is a deliberate design choice (not a bug). Adding the parenthetical makes it testable and unambiguous.

### MEDIUM — Ambiguous AC in US-03

> "WrappedText exposes a `lines: [String]` property (or equivalent resolved approach)"

Change to:

> "WrappedText exposes a `lines: [String]` property populated during `LayoutEngine` layout" — with a note: "(Pending DESIGN wave decision: if Option C is chosen, this AC is replaced by 'Each WrappedText child is a Text view node accessible to the renderer via containerChildren'.)"

### MEDIUM — Missing boundary scenario in US-01

Add one scenario (does not change story size — still 5 scenarios, well within 7-scenario cap):

> Scenario: Text that exactly fits one line produces exactly one child without overflow
> Given content measuring exactly `maxWidth` wide using the injected measurer
> When layout runs
> Then exactly 1 child LayoutNode is produced

## Verdict

**Conditionally approved.** The three HIGH/MEDIUM items are remediations, not rewrites. They can be applied inline before DESIGN wave handoff. No DoR failures. DoR all 9 items pass across all stories. Approved to proceed to handoff after remediations are applied.
