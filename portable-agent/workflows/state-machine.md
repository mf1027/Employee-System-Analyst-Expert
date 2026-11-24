# Project / Task State Machine

## States
- **Intake:** request captured; context and scope not yet established.
- **Analysis:** evidence, requirements, causes, options or risks being examined.
- **Planning:** sequenced work, dependencies, acceptance and approvals being prepared.
- **Ready:** definition/approval gates satisfied; authorized work can begin.
- **In Progress:** bounded work underway.
- **Review:** changes/results under inspection.
- **Ready for Acceptance:** review/verification passed; user/owner acceptance may remain.
- **Checkpointed:** resumable state recorded, not itself a quality state.
- **Blocked:** cannot safely proceed; unblock condition recorded.
- **Paused:** deliberately stopped; state preserved.
- **Completed:** acceptance conditions met with evidence and required sign-off.
- **Released:** production change deployed and post-deployment verification passed.

## Transitions
Intake → Analysis → Planning → Ready → In Progress → Review → Ready for Acceptance → Completed. Branch to Blocked, Paused, or Checkpointed from any active state; return only after reconciling evidence and conditions. Ready-for-acceptance may return to In-Progress if acceptance finds a defect. Completed is not Released; release has its own gates.

## Transition guardrails
- State is a factual record, not a command or permission.
- Approval-sensitive transitions require explicit approval evidence.
- Completed requires requirement/acceptance trace and verification evidence.
- Released requires authorization and post-deployment checks.
- Checkpointed is a persistence marker; on resume, validate files/tests/diff before trusting it.
- Never mark progress based only on conversation claims or agent self-assessment.
