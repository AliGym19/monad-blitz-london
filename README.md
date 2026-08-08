# AO — Authored Objective

An objective function that lives on-chain, where a machine can correct its
numbers but only a human can change its words — and every correction is a
diff anyone can read.

> A learned objective fails silently and can only be disliked; an authored
> one fails at an address and can be contradicted. AO is that address,
> deployed.

## How it works

The constitutional split, enforced in code:

- **Terms** are the vocabulary: human-named costs with a written theory of
  why they exist (`data-purchase`, `retry-premium`). Only the author's
  signature can create, amend, or refuse them. The legislative layer.
- **Parameters** are the numbers inside terms (price ceilings, caps), each
  with written bounds and optionally a ⟂ mark meaning "guessed, never
  measured." A registered SRI agent can update these — but only within
  bounds, only with ≥5 cited residuals, only for number-wrong diagnoses.
  The civil-servant layer.
- **Residuals** are the repair channel: anyone can submit "the prior said X,
  the world said Y" with evidence. They accumulate, get diagnosed one of
  four ways, and either close a ⟂ mark (routine) or open a proposal that
  sits inert until the author signs (legislative).
- **Cited payments** make it live: the agent spends real MON, but every
  payment must reference the term authorising it and sit under the authored
  ceiling, or the contract reverts.

Specs live in [`docs/`](docs/): [term registry](docs/01-TERM-REGISTRY.md),
[parameter scope](docs/02-PARAMETER-SCOPE.md),
[residuals & escalation](docs/03-RESIDUALS-AND-ESCALATION.md).

## Setup

Requires [Foundry](https://book.getfoundry.sh/).

```shell
forge build
```

Create a deployer keystore (once):

```shell
cast wallet import monad-deployer --private-key $(cast wallet new | grep 'Private key:' | awk '{print $3}')
cast wallet address --account monad-deployer   # fund this on Monad testnet
```

## Deploy & seed

Deploys AO and seeds the initial authored manifest (3 terms, 4 parameters,
2 open ⟂ marks) in one broadcast. The deployer becomes the author.

```shell
export SRI_ADDRESS=0x...   # the agent wallet
forge script script/Seed.s.sol:Seed \
  --rpc-url https://testnet-rpc.monad.xyz \
  --account monad-deployer --broadcast
```

Verify on [Monad explorer](https://testnet.monadexplorer.com):

```shell
forge verify-contract <address> src/AO.sol:AO \
  --chain 10143 --verifier sourcify \
  --verifier-url https://sourcify-api-monad.blockvision.org
```

## Layout

- `src/AO.sol` — the contract: terms, parameters, residuals, cited payments
- `script/Seed.s.sol` — deploy + seed the authored manifest
- `docs/` — the three governing specs

Built on the [foundry-monad](https://github.com/monad-developers/foundry-monad)
template (Monad testnet, chain 10143, default RPC in `foundry.toml`).
