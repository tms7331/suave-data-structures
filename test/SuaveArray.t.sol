// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "suave-std/Test.sol";
import "suave-std/suavelib/Suave.sol";
import "forge-std/console.sol";
import {ExampleContract} from "../src/SuaveArray.sol";

contract TestForge is Test, SuaveEnabled {
    function testMap() public {
        ExampleContract d = new ExampleContract();

        bytes memory o1 = d.initArray();
        address(d).call(o1);

        d.arrayInteract();
    }
}
