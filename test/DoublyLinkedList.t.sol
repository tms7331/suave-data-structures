// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "suave-std/Test.sol";
import "suave-std/suavelib/Suave.sol";
import "forge-std/console.sol";
import {DoublyLinkedList} from "../src/DoublyLinkedList.sol";

contract TestForge is Test, SuaveEnabled {
    function testInitHeap() public {
        DoublyLinkedList d = new DoublyLinkedList();

        bytes memory o1 = d.initLinkedList();
        address(d).call(o1);
        // Add assertions for non-null headId and tailId?
    }

    function testPushHead() public {
        DoublyLinkedList d = new DoublyLinkedList();
        bytes memory o1 = d.initLinkedList();
        address(d).call(o1);

        d.pushHead(1);
        d.pushHead(2);
        d.pushHead(3);
        d.display();
    }

    function testPushTail() public {
        DoublyLinkedList d = new DoublyLinkedList();
        bytes memory o1 = d.initLinkedList();
        address(d).call(o1);

        d.pushTail(4);
        d.pushTail(5);
        d.pushTail(6);
        d.display();
    }

    function testPopHead() public {
        DoublyLinkedList d = new DoublyLinkedList();
        bytes memory o1 = d.initLinkedList();
        address(d).call(o1);

        d.pushHead(3);
        d.pushTail(4);
        d.popHead();
        d.display();
    }

    function testPopTail() public {
        DoublyLinkedList d = new DoublyLinkedList();
        bytes memory o1 = d.initLinkedList();
        address(d).call(o1);

        d.pushHead(3);
        d.pushTail(4);
        d.popTail();
        d.display();
    }

    function testIntegration() public {
        DoublyLinkedList d = new DoublyLinkedList();

        bytes memory o1 = d.initLinkedList();
        address(d).call(o1);
        d.pushHead(1);
        d.pushHead(2);
        d.pushHead(3);
        d.pushTail(4);
        d.pushTail(5);
        d.pushTail(6);
        d.display();
        console.log("---");

        d.popHead();
        d.popHead();
        d.display();
        console.log("---");

        d.popTail();
        d.popTail();
        d.display();
    }
}
