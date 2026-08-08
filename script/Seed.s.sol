// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {AO} from "../src/AO.sol";

/// @notice Deploys AO and seeds the initial authored manifest in one broadcast.
///
/// Usage:
///   export SRI_ADDRESS=0x...           # the agent wallet
///   forge script script/Seed.s.sol:Seed \
///     --rpc-url https://testnet-rpc.monad.xyz \
///     --account monad-deployer --broadcast
///
/// The deployer becomes the author. Standing sits with the key that signs this.
contract Seed is Script {
    function run() external {
        address sri = vm.envAddress("SRI_ADDRESS");

        vm.startBroadcast();

        // Deploy with 0.5 MON treasury for cited payments.
        AO ao = new AO{value: 0.5 ether}(sri);
        console.log("AO deployed:", address(ao));

        // ── TERM 1 · data-purchase (Shared) ──────────────────────
        uint256 t1 = ao.authorTerm(
            "data-purchase",
            "The agent may buy datasets or eval results from external endpoints. "
            "This cost exists because the objective values fresh ground truth over "
            "stale priors. Every purchase must cite this term.",
            AO.Scope.Shared,
            ""
        );
        // price ceiling per purchase: GUESSED. Never measured a market rate. Marked.
        uint256 p1 = ao.authorParameter(
            t1, "price-ceiling-wei",
            int256(0.02 ether),            // prior: 0.02 MON per purchase
            int256(0.001 ether),           // SRI may move it down to 0.001
            int256(0.05 ether),            // ...or up to 0.05. Beyond that: the pen.
            true                           // bottom mark
        );
        // daily spend cap: authored policy, not an estimate. Unmarked, tight bounds.
        ao.authorParameter(
            t1, "daily-cap-wei",
            int256(0.1 ether),
            int256(0.1 ether),             // bounds pinned: SRI cannot move policy
            int256(0.1 ether),
            false
        );

        // ── TERM 2 · counterparty-vetting (Shared) ───────────────
        uint256 t2 = ao.authorTerm(
            "counterparty-vetting",
            "The agent pays only endpoints with a registered identity. This cost "
            "exists because an unidentified counterparty makes the payment trail "
            "illegible one level down.",
            AO.Scope.Shared,
            ""
        );
        ao.authorParameter(
            t2, "min-identity-level",
            int256(1), int256(1), int256(3), false
        );

        // ── TERM 3 · retry-premium (Conditional) ─────────────────
        uint256 t3 = ao.authorTerm(
            "retry-premium",
            "A failed purchase that must be retried costs more than its price: "
            "the retry re-runs vetting and delays downstream work.",
            AO.Scope.Conditional,
            "Applies only when an endpoint fails mid-purchase and is retried."
        );
        // premium in basis points over base price: GUESSED. Marked.
        ao.authorParameter(
            t3, "retry-premium-bps",
            int256(500),                   // prior guess: 5%
            int256(0), int256(2000),
            true
        );

        vm.stopBroadcast();

        console.log("Seeded: 3 terms, 4 parameters, 2 bottom marks open.");
        console.log("p1 (price-ceiling-wei) id:", p1);
    }
}
