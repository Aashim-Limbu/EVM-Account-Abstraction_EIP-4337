// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {Script, console} from "forge-std/Script.sol";
import {MinimalAccount} from "../src/ethereum/MinimalAccount.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployMinimal is Script {
    MinimalAccount private s_minimalAccount;
    HelperConfig private s_helperConfig;

    function run() public {
        (s_helperConfig, s_minimalAccount) = deployMinimalAccount();
    }

    function deployMinimalAccount() public returns (HelperConfig helperConfig, MinimalAccount minimalAccount) {
        helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        vm.startBroadcast(config.account);
        minimalAccount = new MinimalAccount(config.entryPoint);
        console.log("minimal Account Owner: ", msg.sender);
        minimalAccount.transferOwnership(config.account);
        vm.stopBroadcast();
    }
}
