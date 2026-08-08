# 01 · Term Registry

The vocabulary of the objective. A term is a human-named cost with a written
theory of why it exists. Terms are the legislative layer: only the author's
signature creates, amends, or refuses them. The SRI agent can propose; it
cannot commit. Reality votes on parameters; authors vote on terms.

## Indexing scheme

Terms are indexed by monotonically increasing uint256 on-chain (`termCount`).
The on-chain record is canonical. This file is the human-readable mirror and
must cite the on-chain id for every entry. If this file and the chain
disagree, the chain wins — this file is documentation, not law.

Every term carries: `id`, `name`, `theory` (why the cost exists, plain text),
`scope` (Shared | Conditional + condition text), `version` (bumps on every
amendment), `authoredAt`. The version history is the amendment record: every
`TermAmended` event on-chain carries a reason string signed by the author.

## Seeded terms (genesis manifest)

### Term 1 · data-purchase — Shared — v1

The agent may buy datasets or eval results from external endpoints. This cost
exists because the objective values fresh ground truth over stale priors.
Every purchase must cite this term. Parameters: `price-ceiling-wei` (⟂),
`daily-cap-wei` (pinned policy).

### Term 2 · counterparty-vetting — Shared — v1

The agent pays only endpoints with a registered identity. This cost exists
because an unidentified counterparty makes the payment trail illegible one
level down: an auditor descending into the evidence would hit an address with
no name. Parameter: `min-identity-level`.

### Term 3 · retry-premium — Conditional — v1

Condition: applies only when an endpoint fails mid-purchase and is retried.
A failed purchase costs more than its price: the retry re-runs vetting and
delays downstream work. Parameter: `retry-premium-bps` (⟂).

## Amendment rules

1. Adding a term: author calls `authorTerm`, or ratifies an SRI proposal
   carrying a FormWrong diagnosis. Either way the signature is the author's.
2. Amending scope: author calls `amendTerm` with a reason, or ratifies a
   ScopeWrong proposal. Version bumps; the reason is in the event log.
3. Refusing a proposal: `refuseProposal` requires a non-empty reason string.
   A cost can be priced, or refused with a reason. Never silently dropped.
4. No term is ever deleted. A term that no longer applies gets its scope
   amended to Conditional with a condition that documents its retirement.
   Deletion would erase the trail; amendment extends it.
