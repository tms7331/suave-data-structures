// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "suave-std/suavelib/Suave.sol";
import "forge-std/console.sol";

contract DoublyLinkedList {
    address[] addressList;

    // Used as 'null' dataId for head and tail nodes
    Suave.DataId nullId = Suave.DataId.wrap(0x00000000000000000000000000000000);

    // Immutable values for 'HeadTailPointer' instances which will contain head and tail dataIds
    Suave.DataId public headId;
    Suave.DataId public tailId;

    struct HeadTailPointer {
        Suave.DataId ref;
    }

    struct Node {
        uint256 val;
        Suave.DataId parent;
        Suave.DataId child;
    }

    constructor() {
        addressList = new address[](1);
        // from Suave.sol: address public constant ANYALLOWED = 0xC8df3686b4Afb2BB53e60EAe97EF043FE03Fb829;
        addressList[0] = 0xC8df3686b4Afb2BB53e60EAe97EF043FE03Fb829;
    }

    /**
     * @notice Essentially a second constructor, has to be separate since it accesses confidential store
     */
    function initLinkedList() external returns (bytes memory) {
        Suave.DataId _headId = buildHeadTailPointer();
        Suave.DataId _tailId = buildHeadTailPointer();
        return abi.encodeWithSelector(this.setLinkedList.selector, _headId, _tailId);
    }

    // CALLBACKS

    function nullCallback() public payable {}

    function setLinkedList(Suave.DataId _headId, Suave.DataId _tailId) public payable {
        require(Suave.DataId.unwrap(headId) == Suave.DataId.unwrap(nullId), "Already initialized");
        headId = _headId;
        tailId = _tailId;
    }

    // CONFIDENTIAL STORE HELPER FUNCTIONS

    function buildHeadTailPointer() internal returns (Suave.DataId) {
        Suave.DataRecord memory record = Suave.newDataRecord(0, addressList, addressList, "headTailPointer");
        writeRef(record.id, nullId);
        return record.id;
    }

    /**
     * @notice Returns the DataId for the head or tail of the linked list.
     * @param headTailId Must be one of public state headId or tailId.
     */
    function getRef(Suave.DataId headTailId) internal view returns (Suave.DataId) {
        bool eqHead = Suave.DataId.unwrap(headTailId) == Suave.DataId.unwrap(headId);
        bool eqTail = Suave.DataId.unwrap(headTailId) == Suave.DataId.unwrap(tailId);
        require(eqHead || eqTail, "Invalid headTailId");

        bytes memory value = Suave.confidentialRetrieve(headTailId, "suavedll:v0:headTailPointer");
        HeadTailPointer memory headTailPointer = abi.decode(value, (HeadTailPointer));
        return headTailPointer.ref;
    }

    function writeRef(Suave.DataId storeId, Suave.DataId ref) internal {
        HeadTailPointer memory headTailPointer = HeadTailPointer(ref);
        bytes memory value = abi.encode(headTailPointer);
        Suave.confidentialStore(storeId, "suavedll:v0:headTailPointer", value);
    }

    /**
     * @notice Retreives a node from the confidential store.
     * @param nodeId DataId for the node to be retrieved.
     */
    function getNode(Suave.DataId nodeId) internal returns (Node memory node) {
        require(Suave.DataId.unwrap(nodeId) != Suave.DataId.unwrap(nullId), "Node does not exist");
        bytes memory value = Suave.confidentialRetrieve(nodeId, "suavedll:v0:node");
        node = abi.decode(value, (Node));
        return node;
    }

    /**
     * @notice Writes a node to the confidential store.
     * @param nodeId DataId for the node to be written
     * @param node Node struct to be written
     */
    function writeNode(Suave.DataId nodeId, Node memory node) internal {
        bytes memory value = abi.encode(node);
        Suave.confidentialStore(nodeId, "suavedll:v0:node", value);
    }

    /**
     * @notice Takes in raw fields for a node and creates a new node
     * @dev Used only for node creation, to update existing nodes 'writeNode' should be used
     */
    function createNode(uint256 val, Suave.DataId parent, Suave.DataId child) internal returns (Suave.DataId) {
        Suave.DataRecord memory record = Suave.newDataRecord(0, addressList, addressList, "node");
        Node memory node = Node(val, parent, child);
        bytes memory value = abi.encode(node);
        Suave.confidentialStore(record.id, "suavedll:v0:node", value);
        return record.id;
    }

    // USER FUNCTIONS

    /**
     * @notice Push a uint to the head of the linked list
     */
    function pushHead(uint256 val) external returns (bytes memory) {
        // Steps:
        // Create a new node for this value
        // Set that node's child to be the previous head
        // Set the previous head's parent to be the new node

        Suave.DataId _headId = getRef(headId);
        Suave.DataId recordId = createNode(val, nullId, _headId);
        if (Suave.DataId.unwrap(_headId) == Suave.DataId.unwrap(nullId)) {
            writeRef(headId, recordId);
            writeRef(tailId, recordId);
        } else {
            // Current head should have new node as parent, same child
            Node memory headNode = getNode(_headId);
            headNode.parent = recordId;
            writeNode(_headId, headNode);

            writeRef(headId, recordId);
        }

        return abi.encodeWithSelector(this.nullCallback.selector);
    }

    /**
     * @notice Push a uint to the tail of the linked list
     */
    function pushTail(uint256 val) external returns (bytes memory) {
        // Steps:
        // Create a new node for this value
        // Set that node's parent to be the current tail
        // Set the previous tails's child to be the new node

        Suave.DataId _tailId = getRef(tailId);
        Suave.DataId recordId = createNode(val, _tailId, nullId);
        if (Suave.DataId.unwrap(_tailId) == Suave.DataId.unwrap(nullId)) {
            writeRef(headId, recordId);
            writeRef(tailId, recordId);
        } else {
            // Current tail should have new node as child, same parent
            Node memory tailNode = getNode(_tailId);
            tailNode.child = recordId;
            writeNode(_tailId, tailNode);
            writeRef(tailId, recordId);
        }

        return abi.encodeWithSelector(this.nullCallback.selector);
    }

    /**
     * @notice Pop the current head off the linked list
     */
    function popHead() external returns (bytes memory) {
        // Steps:
        // Set the head's child to be the new head
        // If there is no child - set head AND tail to null...

        Suave.DataId _headId = getRef(headId);

        // If we have no head this will revert
        Node memory headNode = getNode(_headId);

        if (Suave.DataId.unwrap(headNode.child) == Suave.DataId.unwrap(nullId)) {
            writeRef(headId, nullId);
            writeRef(tailId, nullId);
        } else {
            writeRef(headId, headNode.child);
            Node memory node = getNode(headNode.child);
            node.parent = nullId;
            writeNode(headNode.child, node);
        }

        return abi.encodeWithSelector(this.nullCallback.selector);
    }

    /**
     * @notice Pop the current tail off the linked list
     */
    function popTail() external returns (bytes memory) {
        // Steps:
        // Set the tails's parent to be the new head
        // If there is no tail - set head AND tail to null...

        Suave.DataId _tailId = getRef(tailId);

        // If we have no tail, this will revert
        Node memory tailNode = getNode(_tailId);

        if (Suave.DataId.unwrap(tailNode.parent) == Suave.DataId.unwrap(nullId)) {
            writeRef(headId, nullId);
            writeRef(tailId, nullId);
        } else {
            writeRef(tailId, tailNode.parent);
            Node memory node = getNode(tailNode.parent);
            node.child = nullId;
            writeNode(tailNode.parent, node);
        }
        return abi.encodeWithSelector(this.nullCallback.selector);
    }

    /**
     * @notice Iterate through all elements in the linked list and print them. Used for debugging.
     */
    function display() external returns (bytes memory) {
        Suave.DataId nodeId = getRef(headId);
        while (true) {
            if (Suave.DataId.unwrap(nodeId) == Suave.DataId.unwrap(nullId)) {
                break;
            }
            Node memory node = getNode(nodeId);
            console.log(node.val);
            nodeId = node.child;
        }

        return abi.encodeWithSelector(this.nullCallback.selector);
    }
}
