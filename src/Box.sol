//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Box is Ownable {
    uint256 private s_value;

    event ValueChanged(uint256 oldValue, uint256 newValue);

    constructor() Ownable(msg.sender) {}

    function set(uint256 _value) public onlyOwner {
        s_value = _value;
        emit ValueChanged(s_value, _value);
    }

    function value() public view returns (uint256) {
        return s_value;
    }
}
