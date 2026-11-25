# Video Intelligence

## Purpose
Analyse video content for business intelligence, training assessment, process observation, or quality assurance purposes. Extract structured observations, timeline annotations, and findings from video evidence.

## When to use
Invoke when asked to analyse video content, review training footage, observe process execution, assess presentation quality, or when video evidence is provided as input to an investigation or audit.

## Prerequisites
- Access to the video content (file path, URL, or transcript).
- Analysis objective: what question should the analysis answer?
- Context: what process, training, or activity is shown.

## Procedure

1. **Define the analysis objective.** What specific question does this video analysis answer? State it explicitly before watching.

2. **Observe and annotate:**
   a. Note key events with timestamps: [MM:SS] — Event description.
   b. Identify participants, roles, and actions.
   c. Track process steps observed vs expected process flow.
   d. Note deviations from standard procedure.
   e. Note communication patterns, decision points, and handoffs.

3. **Classify observations:**
   - **Process compliance:** steps followed, steps skipped, steps done out of order.
   - **Quality indicators:** errors, corrections, rework, confusion points.
   - **Communication:** clarity, completeness, confirmation/acknowledgment patterns.
   - **Safety/security:** violations, near-misses, unsafe practices.
   - **Training effectiveness:** participant comprehension, engagement, skill demonstration.

4. **Cross-reference against standards:**
   - If a standard operating procedure (SOP) exists, map observed behavior to SOP steps.
   - Identify gaps between documented procedure and actual practice.
   - Note whether deviations are improvements or degradations.

5. **Quantify where possible:**
   - Time per process step vs expected duration.
   - Error count and type distribution.
   - Compliance percentage (steps followed / total required steps).

6. **Produce findings:**
   - Structured by category (compliance, quality, communication, safety).
   - Each finding has a timestamp reference, severity, and recommendation.
   - Distinguish observations (what happened) from interpretations (what it means).

## Output contract
- Timeline annotations: Timestamp | Event | Category | Notes
- Findings table: ID | Finding | Severity | Timestamp | Recommendation
- Process compliance summary (if SOP comparison applies).
- Key observations and recommendations.

## Safety and approval gates
- Video analysis is analysis — do not modify or redistribute video content.
- Do not identify individuals by name unless instructed; use roles.
- Handle any PII visible in the video according to privacy policies.
- Flag safety or security violations immediately, regardless of analysis scope.

## Verification
- Observations are timestamped and verifiable by reviewing the referenced segment.
- Findings distinguish fact (observed) from interpretation (analyst assessment).
- Recommendations are specific and actionable.
- SOP comparison (if applicable) covers all required steps.
