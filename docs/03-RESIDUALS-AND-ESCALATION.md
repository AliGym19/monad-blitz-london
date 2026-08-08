# 03 · Residual Calculus & Escalation Boundaries

Residuals are the only raw material the loop runs on. This document fixes the
arithmetic the SRI agent uses to turn accumulated residuals into one of four
diagnoses, and the boundaries that decide what may be committed, what must be
escalated, and what must wait. The contract enforces the floor (sample count,
bounds, evidence citation); this document is the agent's reasoning policy
above that floor. The reasoning document for every commit and proposal is
hashed on-chain (`reasoningHash`) and must be reproducible from this spec —
audit descends.

## Residual definition

For parameter p with current value v, one residual r is:

    e(r) = (observed − predicted) / predicted        (relative error)

predicted is read from the chain at request time (not from agent memory — the
chain is the prior). observed comes from the instrument named in
02-PARAMETER-SCOPE. Both are submitted raw via `submitResidual`; the relative
error is computed at diagnosis time, off-chain, reproducibly.

## Cluster formation

A cluster is the set of unconsumed residuals on one parameter. Diagnosis runs
when the cluster reaches n ≥ 5 (MIN_SAMPLES, mirrored on-chain). Below 5,
the state is InsufficientEvidence by definition — one residual means nothing.

Statistics per cluster: median error ẽ, sign consistency s = max(#pos, #neg)/n,
interquartile range IQR of e, and dispersion ratio D = IQR / |ẽ|.

## The four-way diagnosis (evaluated in this order)

1. InsufficientEvidence — n < 5, or D > 2.0. High dispersion means the
   residuals do not agree with each other; committing on them would be
   fitting noise. Action: none. Wait for overlapping samples.

2. ScopeWrong — dispersion is high but a partition explains it: split the
   cluster by any recorded evidence feature (counterparty, time-of-day,
   retry-flag). If some binary partition reduces pooled variance by more than
   50%, the term is real but conditional — true of one side of the split,
   not of everything. Action: `openProposal(AmendScope, ScopeWrong, ...)`
   with the partition stated in the reasoning document. Sits inert until the
   author signs.

3. NumberWrong — |ẽ| > 0.15 and s ≥ 0.8 and D ≤ 2.0. The residuals agree
   with each other and disagree with the prior: the term is fine, the value
   moves. Proposed value: median of observed, clamped to the parameter's
   written bounds. If the clamp binds (median falls outside bounds), do NOT
   commit at the bound — the world is saying the written scope itself is too
   narrow, and widening scope is the author's call: escalate as ScopeWrong
   with the clamp noted. Otherwise: `commitParameter`. The ⟂ mark closes.
   Consumed residuals are spent forever (on-chain flag) — evidence cites
   once, preventing double-counted certainty.

4. FormWrong — the cluster is consistent (s ≥ 0.8, D ≤ 2.0) but |ẽ| persists
   after a NumberWrong commit on the same parameter (a second cluster forms
   with the same sign within the next 10 samples), or the error correlates
   with an event count rather than the priced quantity (e.g., cost scales
   with number of handles, not with price — a per-event cost the vocabulary
   lacks). The number cannot absorb it because no number of this term can:
   the vocabulary is missing a word. Action: `openProposal(AddTerm,
   FormWrong, ...)` with a proposed name, theory, and the residual evidence.
   The fuse does not hold the pen.

## Boundary constants (agent policy, tunable by author only)

    MIN_SAMPLES        = 5        (mirrored in contract, hard floor)
    ERROR_THRESHOLD    = 0.15     (|median error| to trigger NumberWrong)
    SIGN_CONSISTENCY   = 0.8      (fraction sharing the majority sign)
    DISPERSION_MAX     = 2.0      (IQR / |median| above this → wait)
    PARTITION_GAIN     = 0.5      (variance reduction to claim ScopeWrong)
    RECURRENCE_WINDOW  = 10       (samples after a commit in which a
                                   same-sign recluster signals FormWrong)

These constants are themselves parameters of the diagnosis policy, and the
honest admission is that every one of them is currently ⟂ — guessed, never
measured. They live here, in a signed file in the repo, not in the agent's
weights: wrong in a fixed, inspectable way.

## Escalation summary

Commit (SRI alone): NumberWrong within bounds. Everything the contract
permits the SRI is exactly this and nothing else.

Escalate (proposal, author signs): ScopeWrong, FormWrong, and any
NumberWrong whose honest value falls outside written bounds.

Wait: InsufficientEvidence. Waiting is a diagnosis, not an absence of one —
the UI shows it as a held state with the sample count, so a spectator can
see the system declining to conclude.
