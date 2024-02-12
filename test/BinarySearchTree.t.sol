// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "suave-std/Test.sol";
import "suave-std/suavelib/Suave.sol";
import "forge-std/console.sol";
import {BinarySearchTree} from "../src/BinarySearchTree.sol";

contract TestForge is Test, SuaveEnabled {
    function testInsert() public {
        BinarySearchTree d = new BinarySearchTree();

        bytes memory o1 = d.initBinaryTree();
        address(d).call(o1);

        d.insert(5);
        d.insert(3);
        d.insert(8);
        d.insert(8);
        d.insert(15);
        d.insert(1);
        d.display();
    }
}
