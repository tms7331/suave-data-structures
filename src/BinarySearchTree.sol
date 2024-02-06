// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "suave-std/suavelib/Suave.sol";
import "forge-std/console.sol";

contract BinarySearchTree {
    address[] addressList;

    // Used as 'null' dataId for head and tail nodes
    Suave.DataId nullId = Suave.DataId.wrap(0x00000000000000000000000000000000);

    // Immutable value for 'RootPointer' instance which will contain reference to root node
    Suave.DataId public rootPointerId;

    struct RootPointer {
        Suave.DataId ref;
    }

    struct Node {
        uint val;
        Suave.DataId left;
        Suave.DataId right;
    }

    constructor() {
        addressList = new address[](1);
        // from Suave.sol: address public constant ANYALLOWED = 0xC8df3686b4Afb2BB53e60EAe97EF043FE03Fb829;
        addressList[0] = 0xC8df3686b4Afb2BB53e60EAe97EF043FE03Fb829;
    }

    /**
     * @notice Essentially a second constructor, has to be separate since it accesses confidential store
     */
    function initBinaryTree() external returns (bytes memory) {
        Suave.DataId _rootPointerId = buildRootPointer();
        return
            abi.encodeWithSelector(this.setBinaryTree.selector, _rootPointerId);
    }

    // CALLBACKS

    function nullCallback() public payable {}

    function setBinaryTree(
        Suave.DataId _rootPointerId
    ) public payable {
        require(Suave.DataId.unwrap(rootPointerId) == Suave.DataId.unwrap(nullId), "Already initialized");
        rootPointerId = _rootPointerId;
    }

    // CONFIDENTIAL STORE HELPER FUNCTIONS

    function buildRootPointer() internal returns (Suave.DataId) {
        Suave.DataRecord memory record = Suave.newDataRecord(
            0,
            addressList,
            addressList,
            "rootPointer"
        );
        writeRef(record.id, nullId);
        return record.id;
    }

    /**
     * @notice Returns the DataId for the root of the binary tree
     */
    function getRef() internal view returns (Suave.DataId) {
        bytes memory value = Suave.confidentialRetrieve(
            rootPointerId,
            "suavebst:v0:rootPointer"
        );
        RootPointer memory rootPointer = abi.decode(
            value,
            (RootPointer)
        );
        return rootPointer.ref;
    }

    function writeRef(Suave.DataId storeId, Suave.DataId ref) internal {
        RootPointer memory rootPointer = RootPointer(ref);
        bytes memory value = abi.encode(rootPointer);
        Suave.confidentialStore(storeId, "suavebst:v0:rootPointer", value);
    }

    /**
     * @notice Retreives a node from the confidential store.
     * @param nodeId DataId for the node to be retrieved.
     */
    function getNode(Suave.DataId nodeId) internal returns (Node memory node) {
        require(
            Suave.DataId.unwrap(nodeId) != Suave.DataId.unwrap(nullId),
            "Node does not exist"
        );
        bytes memory value = Suave.confidentialRetrieve(
            nodeId,
            "suavebst:v0:node"
        );
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
        Suave.confidentialStore(nodeId, "suavebst:v0:node", value);
    }

    /**
     * @notice Takes in raw fields for a node and creates a new node
     * @dev Used only for node creation, to update existing nodes 'writeNode' should be used
     */
    function createNode(uint val) internal returns (Suave.DataId) {
        Suave.DataRecord memory record = Suave.newDataRecord(
            0,
            addressList,
            addressList,
            "node"
        );
        // New nodes will always be leaf nodes
        Node memory node = Node(val, nullId, nullId);
        bytes memory value = abi.encode(node);
        Suave.confidentialStore(record.id, "suavebst:v0:node", value);
        return record.id;
    }


    /**
     * @notice Recursive insert into tree below specified node
     */
    function _insert(Suave.DataId nodeId, Node memory node, uint val) internal {
        // Always inserting to a leaf node
        // If it's smaller than current node - insert recursively to the left
        // Otherwise - insert recursively to the right
        if (val < node.val) {
            if (Suave.DataId.unwrap(node.left) != Suave.DataId.unwrap(nullId)) {
                Node memory nodeLeft = getNode(node.left);
                _insert(node.left, nodeLeft, val);
            }
            else {
                Suave.DataId recordId = createNode(val);
                node.left = recordId;
                writeNode(nodeId, node);
            }
        }
        else {
            if (Suave.DataId.unwrap(node.right) != Suave.DataId.unwrap(nullId)) {
                Node memory nodeRight = getNode(node.right);
                _insert(node.right, nodeRight, val);
            }
            else {
                Suave.DataId recordId = createNode(val);
                node.right = recordId;
                writeNode(nodeId, node);
            }

        }
    }

    function _display(Node memory node) internal {
        if (Suave.DataId.unwrap(node.left) != Suave.DataId.unwrap(nullId)) {
           Node memory nodeLeft = getNode(node.left);
            _display(nodeLeft);
        }
        console.log(node.val);
        if (Suave.DataId.unwrap(node.right) != Suave.DataId.unwrap(nullId)) {
           Node memory nodeRight = getNode(node.right);
            _display(nodeRight);
        }
    }


    // USER FUNCTIONS

    /**
     * @notice Insert a value into the binary tree
     */
    function insert(uint val) external returns (bytes memory) {
        Suave.DataId _rootId = getRef();
        if (Suave.DataId.unwrap(_rootId) != Suave.DataId.unwrap(nullId)) {
            Node memory node = getNode(_rootId);
            _insert(_rootId, node, val);
        }
        else {
            Suave.DataId recordId = createNode(val);
            writeRef(rootPointerId, recordId);
        }
        return abi.encodeWithSelector(this.nullCallback.selector);
    }

    /**
     * @notice Iterate through all elements in the binary tree in order and print them. Used for debugging.
     */
    function display() external returns (bytes memory) {
        Suave.DataId rootId = getRef();
        if (Suave.DataId.unwrap(rootId) != Suave.DataId.unwrap(nullId)) {
            Node memory node = getNode(rootId);
            _display(node);
        }
        return abi.encodeWithSelector(this.nullCallback.selector);
    }
}
