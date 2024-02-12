// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "suave-std/suavelib/Suave.sol";
import "forge-std/console.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

library SuaveArray {
    // To use library, a contract must instantiate this struct and store it in the confidential store
    struct ArrayMetadata {
        uint256 length;
        Suave.DataId ref;
    }

    /**
     * @notice Retreives array info.  This must be obtained in order to interact with array
     */
    function getMetadata(Suave.DataId ref) internal returns (ArrayMetadata memory) {
        bytes memory val = Suave.confidentialRetrieve(ref, "metadata");
        ArrayMetadata memory am = abi.decode(val, (ArrayMetadata));
        return am;
    }

    /**
     * @notice Overwrites array info
     */
    function setMetadata(ArrayMetadata memory am) internal {
        Suave.confidentialStore(am.ref, "metadata", abi.encode(am));
    }

    /**
     * @notice Retrieves element at specific index
     */
    function get(ArrayMetadata memory a, uint256 index) internal returns (bytes memory) {
        ArrayMetadata memory am = getMetadata(a.ref);
        string memory indexStr = Strings.toString(index);
        bytes memory val = Suave.confidentialRetrieve(am.ref, indexStr);
        return val;
    }

    /**
     * @notice Appends to end of array
     */
    function append(ArrayMetadata memory am, bytes memory value) internal {
        write(am, am.length, value);
        am.length += 1;
        setMetadata(am);
    }

    /**
     * @notice Overwrite an element at specified index
     */
    function write(ArrayMetadata memory am, uint256 index, bytes memory value) internal {
        require(index <= am.length, "Index out of bounds");
        string memory indexStr = Strings.toString(index);
        Suave.confidentialStore(am.ref, indexStr, value);
    }

    /**
     * @notice Deletes an element from the array without preserving ordering
     */
    function delUnordered(ArrayMetadata memory am, uint256 index) internal {
        // Move last element in array to this index
        write(am, index, get(am, am.length - 1));
        am.length -= 1;
        setMetadata(am);
    }

    /**
     * @notice Deletes an element from the array while preserving ordering
     * @dev Moves all elements one to the left, so O(n) and be careful with large arrays
     */
    function del(ArrayMetadata memory am, uint256 index) internal {
        for (uint256 i = index; i < am.length - 1; i++) {
            write(am, i, get(am, i + 1));
        }
        am.length -= 1;
        setMetadata(am);
    }
}

// Example contract to demonstrate how to use SuaveArray library
contract ExampleContract {
    address[] addressList;

    Suave.DataId public arrayRef;

    // We can append arbitrary data to our suave-array, we just have to encode it in bytes
    struct CustomData {
        uint256 val1;
        uint256 val2;
        string s;
    }

    constructor() {
        addressList = new address[](1);
        // from Suave.sol: address public constant ANYALLOWED = 0xC8df3686b4Afb2BB53e60EAe97EF043FE03Fb829;
        addressList[0] = 0xC8df3686b4Afb2BB53e60EAe97EF043FE03Fb829;
    }

    function initArray() external returns (bytes memory) {
        Suave.DataRecord memory record = Suave.newDataRecord(0, addressList, addressList, "suaveArr:v0:dataId");
        SuaveArray.ArrayMetadata memory am = SuaveArray.ArrayMetadata(0, record.id);
        SuaveArray.setMetadata(am);
        return abi.encodeWithSelector(this.setArray.selector, record.id);
    }

    function nullCallback() public payable {}

    function setArray(Suave.DataId _arrayRef) public payable {
        arrayRef = _arrayRef;
    }

    function displayAll(SuaveArray.ArrayMetadata memory am) internal {
        for (uint256 i = 0; i < am.length; i++) {
            bytes memory dat = SuaveArray.get(am, i);
            CustomData memory cd = abi.decode(dat, (CustomData));
            console.log(cd.val1, cd.val2, cd.s);
        }
    }

    function arrayInteract() external returns (bytes memory) {
        SuaveArray.ArrayMetadata memory am = SuaveArray.getMetadata(arrayRef);

        bytes memory val1 = abi.encode(CustomData(1, 9, "a"));
        bytes memory val2 = abi.encode(CustomData(2, 8, "b"));
        bytes memory val3 = abi.encode(CustomData(3, 7, "c"));
        bytes memory val4 = abi.encode(CustomData(4, 6, "d"));
        bytes memory val5 = abi.encode(CustomData(5, 5, "e"));

        SuaveArray.append(am, val1);
        SuaveArray.append(am, val2);
        SuaveArray.append(am, val3);
        SuaveArray.append(am, val4);
        displayAll(am);
        console.log("-------");

        SuaveArray.write(am, 2, val5);
        displayAll(am);
        console.log("-------");

        SuaveArray.del(am, 1);
        SuaveArray.delUnordered(am, 1);
        am = SuaveArray.getMetadata(arrayRef);
        displayAll(am);
        return abi.encodeWithSelector(this.nullCallback.selector);
    }
}
