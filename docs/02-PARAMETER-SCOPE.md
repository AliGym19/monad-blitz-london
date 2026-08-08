# 02 · Parameter Scope & Measurement Plan

A parameter is the value inside a term's container. Parameters are where
learning is permitted: the SRI agent holds commit authority over them, within
written bounds, with cited evidence. This document states, for each parameter:
what is measured, with what instrument, and how the measurement lands on
Monad. A parameter whose measurement plan is blank should not exist.

## The ⟂ discipline

A parameter marked ⟂ (bottomMark = true) is a guess: authored because the
term needed a number, never measured. The mark is an admission, and it is
public — `openMarks()` returns the list, and the UI displays it. A manifest
with no marks is claiming completeness, and nothing over real work is
complete. The mark closes only through `commitParameter` with ≥ MIN_SAMPLES
cited residuals: the moment the value stops being a guess and becomes a
measurement.

## Parameters

### price-ceiling-wei · Term 1 · ⟂ open

Prior 0.02 MON. SRI bounds [0.001, 0.05] MON. Measures the fair per-purchase
price of a dataset from the demo endpoints. Instrument: the agent's own
purchase loop — predicted price is read from this parameter at request time;
observed price is what the endpoint's HTTP 402 quote demanded. Both land
on-chain via `submitResidual(paramId, predicted, observed, evidenceHash)`
where evidenceHash = keccak256 of the canonical JSON of the full quote
(sorted keys, no whitespace — canonicalise before hashing or verification
mismatches on formatting). Monad tie: each residual is a transaction;
0.3s blocks mean the residual lands before the purchase completes, so the
spectator UI shows prediction and contradiction nearly simultaneously.

### daily-cap-wei · Term 1 · pinned

0.1 MON, bounds [0.1, 0.1]. Not a measurement — a policy. Bounds are pinned
so the SRI structurally cannot move it: any commit attempt reverts with
"outside written scope". This parameter exists partly as demo material: it is
the on-screen proof that bounds are law, not suggestion.

### min-identity-level · Term 2 · unmarked

Prior 1, bounds [1, 3]. Levels: 1 = endpoint address is registered in the
demo registry; 2 = registered + has completed a prior purchase; 3 =
registered + ERC-8004 identity on Monad testnet (if the registry is live
there — check on the day; if not, level 3 is defined but unreachable, which
is honest). Instrument: registry lookup at vetting time; the vetting result
hash rides in the purchase's evidence.

### retry-premium-bps · Term 3 · ⟂ open

Prior 500 bps. SRI bounds [0, 2000]. Measures the true overhead of a retried
purchase relative to a clean one. Instrument: wall-clock and gas delta
between first attempt and successful retry, priced into bps of base price.
Observed value = ((retry_total_cost − base_price) / base_price) × 10000.
Conditional scope means residuals for this parameter are only valid when the
retry condition held — the evidence JSON must include the failure record.

## What is deliberately not measured

Endpoint response latency, dataset quality scores, and gas costs of the
agent's own transactions are all real and all unpriced. They are absent
because no term names them. If they matter, they will surface as residual
clusters that no existing parameter explains — which is the FormWrong path,
and it is the system working, not failing. Pre-authoring terms for costs we
have not felt would be prejudgement wearing our own clothes.
