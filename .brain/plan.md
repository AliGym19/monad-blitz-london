# AO (ao-blitz) — Plan

Hackathon: monad-blitz-london. Submission freeze: today (2026-08-08), pitch ~5:45 PM.

## Done looks like (eligibility bar — all five, or no pitch)

1. Fork of monad-blitz-london containing the project — ✓ done 2026-08-08: AliGym19/monad-blitz-london, history pushed, tracking set
2. README with what it is, setup, how to run — ✓ done
3. AO.sol deployed on Monad testnet **during the event** — ✓ done 2026-08-08: `0x06a9c31103F64F27aAb6874Faa82E080bCB01Ae7` (clean freelance genesis; earlier deploys 0x471F9d86…b27F and 0xD12124f5…Ac991 abandoned), seeded (3 terms / 4 params / marks [1,4] / 0.5 MON treasury). Deployer + SRI wallets in `.env`.
4. Live, publicly reachable web app — ✓ done 2026-08-08: https://ao-alitvjaber-1829s-projects.vercel.app (Vercel project `ao`, SSO protection disabled via API, verified 200 + renders chain state)
5. Submitted at blitz.devnads.com before the freeze

## Components (must-have order)

1. **Contract, deployed and seeded** (~30 min) — ✓ written, builds. `forge build` → `forge script script/Seed.s.sol:Seed --broadcast` with `SRI_ADDRESS` set. Result: address on testnet.monadexplorer.com showing 3 terms, 4 params, 2 open ⟂ marks, funded treasury.
2. **SRI agent** (~2 hrs) — script (Python/TS) loop: purchases from a rigged dummy endpoint, `citedPay`, submits residuals; at cluster of 5 runs spec-03 arithmetic → commits (number-wrong) or opens proposal (form/scope-wrong). Rigged prices = deterministic story beats.
3. **Spectator UI** — ✓ done 2026-08-08: `ui/index.html` (single file, viem via esm.sh, 3s poll). Constitution + ⟂ badges + ledger + signature desk with ratify/refuse wired to injected wallet. Deployed and verified rendering live chain state (3 articles / 4 params / 2 marks).
4. **Demo run** (pre-staged, 3 min): two clean cited payments → over-ceiling payment reverts on screen → residual cluster completes, SRI closes a ⟂ mark citing samples → rigged form-wrong cluster, SRI escalates instead of committing → sign on stage, vocabulary amends, address in explorer.

## Kill condition

Freeze deadline passes without the 5-item bar met.

## State (2026-08-08)

- AO.sol + Seed.s.sol imported, compile clean (needed `unicode""` literals + `via_ir`)
- Specs in `docs/`; README rewritten
- Not yet: deploy, SRI agent, UI, submission
