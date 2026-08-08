// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {AO} from "../src/AO.sol";

/// @notice Deploys AO and seeds the freelance rate-card genesis manifest.
/// Usage:
///   export SRI_ADDRESS=0x...
///   forge script script/Seed.s.sol:Seed \
///     --rpc-url https://testnet-rpc.monad.xyz \
///     --account monad-deployer --password "$KEYSTORE_PASSWORD" --broadcast
contract Seed is Script {
    function run() external {
        address sri = vm.envAddress("SRI_ADDRESS");
        vm.startBroadcast();

        AO ao = new AO{value: 0.5 ether}(sri);
        console.log("AO deployed:", address(ao));

        // TERM 1 - task-rate (Shared)
        uint256 t1 = ao.authorTerm(
            "task-rate",
            "The agent commissions freelance tasks and pays contractors on "
            "completion. This cost exists because shipped work deserves a fair "
            "market rate - and because an unpriced rate card is a spreadsheet "
            "that cannot see the work.",
            AO.Scope.Shared,
            ""
        );
        // rate ceiling per task: GUESSED, never measured. Marked.
        ao.authorParameter(t1, "price-ceiling-wei",
            int256(0.02 ether), int256(0.002 ether), int256(0.06 ether), true);
        // daily payout cap: authored policy. Bounds pinned - the fuse cannot move policy.
        ao.authorParameter(t1, "daily-cap-wei",
            int256(0.1 ether), int256(0.1 ether), int256(0.1 ether), false);

        // TERM 2 - client-vetting (Shared)
        uint256 t2 = ao.authorTerm(
            "client-vetting",
            "The agent pays only contractors with a registered identity. An "
            "unidentified payee makes the payout trail illegible one level "
            "down: an auditor descending into the evidence would hit an "
            "address with no name.",
            AO.Scope.Shared,
            ""
        );
        ao.authorParameter(t2, "min-identity-level", int256(1), int256(1), int256(3), false);

        // TERM 3 - revision-premium (Conditional)
        uint256 t3 = ao.authorTerm(
            "revision-premium",
            "A task returned for revision costs more than its rate: the "
            "handback re-runs review and delays downstream work.",
            AO.Scope.Conditional,
            "Applies only when a delivered task is sent back for revision."
        );
        ao.authorParameter(t3, "revision-premium-bps", int256(500), int256(0), int256(2000), true);

        vm.stopBroadcast();
        console.log("Seeded: 3 terms, 4 parameters, 2 bottom marks open.");
    }
}
