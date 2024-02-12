// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "suave-std/Test.sol";
import "suave-std/suavelib/Suave.sol";
import "forge-std/console.sol";
import {ExampleContract} from "../src/SuaveMap.sol";

contract TestForge is Test, SuaveEnabled {
    function testMap() public {
        ExampleContract d = new ExampleContract();

        bytes memory o1 = d.initMap();
        address(d).call(o1);

        d.mapWrite();
        d.mapGet();
    }
}
