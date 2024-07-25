//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";

contract TimeLock is TimelockController {
    /**
     *
     * @param minDelay time day -> how much you want to wait before executing
     * @param proposers addresses of proposers
     * @param execuotrs addresses of executors
     */
    constructor(uint256 minDelay, address[] memory proposers, address[] memory execuotrs)
        TimelockController(minDelay, proposers, execuotrs, msg.sender)
    {}
}
