// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "suave-std/suavelib/Suave.sol";
import "forge-std/console.sol";

library SuaveMap {
    // TODO - add some tracking of keys?  Could we add an array of keys that we can maintain?
    struct MapMetadata {
        Suave.DataId ref;
    }

    /**
     * @notice Retreives map info.  This must be obtained in order to interact with map
     */
    function getMetadata(Suave.DataId ref) internal returns (MapMetadata memory) {
        bytes memory val = Suave.confidentialRetrieve(ref, "metadata");
        MapMetadata memory am = abi.decode(val, (MapMetadata));
        return am;
    }

    /**
     * @notice Overwrites map info
     */
    function setMetadata(MapMetadata memory am) internal {
        Suave.confidentialStore(am.ref, "metadata", abi.encode(am));
    }

    /**
     * @notice Retrieves element corresponding to key
     */
    function get(MapMetadata memory mm, string memory key) internal returns (bytes memory) {
        bytes memory val = Suave.confidentialRetrieve(mm.ref, key);
        // For consistency throw here - if we've deleted we'll have bytes(0),
        // If key doesn't exist we'll get a different failure, but want error each time
        bytes memory noBytes = new bytes(0);
        require(val.length != noBytes.length, "Key not found");
        return val;
    }

    /**
     * @notice Writes key+value
     */
    function write(MapMetadata memory mm, string memory key, bytes memory value) internal {
        Suave.confidentialStore(mm.ref, key, value);
    }

    /**
     * @notice Deletes value at a key
     */
    function del(MapMetadata memory mm, string memory key) internal {
        // TODO - if a user wanted to write this as a value, map would fail,
        // can we track deleted keys instead?
        bytes memory noBytes = new bytes(0);
        write(mm, key, noBytes);
    }
}

contract ExampleContract {
    address[] addressList;

    Suave.DataId public mapRef;

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

    function initMap() external returns (bytes memory) {
        Suave.DataRecord memory record = Suave.newDataRecord(0, addressList, addressList, "suaveMap:v0:dataId");

        SuaveMap.MapMetadata memory am = SuaveMap.MapMetadata(record.id);
        SuaveMap.setMetadata(am);
        return abi.encodeWithSelector(this.setMap.selector, record.id);
    }

    function nullCallback() public payable {}

    // callback to initialize public variables which will be immutable
    function setMap(Suave.DataId _mapRef) public payable {
        mapRef = _mapRef;
    }

    function mapWrite() external returns (bytes memory) {
        SuaveMap.MapMetadata memory mm = SuaveMap.getMetadata(mapRef);

        bytes memory val1 = abi.encode(CustomData(1, 9, "a"));
        bytes memory val2 = abi.encode(CustomData(2, 8, "b"));
        string memory key1 = "k1";
        string memory key2 = "k2";

        SuaveMap.write(mm, key1, val1);
        SuaveMap.write(mm, key2, val2);

        return abi.encodeWithSelector(this.nullCallback.selector);
    }

    function mapGet() external returns (bytes memory) {
        SuaveMap.MapMetadata memory mm = SuaveMap.getMetadata(mapRef);
        string memory key1 = "k1";
        string memory key2 = "k2";

        bytes memory dat1 = SuaveMap.get(mm, key1);
        bytes memory dat2 = SuaveMap.get(mm, key2);
        CustomData memory cd1 = abi.decode(dat1, (CustomData));
        CustomData memory cd2 = abi.decode(dat2, (CustomData));
        console.log("GOT VALUES:");
        console.log(cd1.val1, cd1.val2, cd1.s);
        console.log(cd2.val1, cd2.val2, cd2.s);
        return abi.encodeWithSelector(this.nullCallback.selector);
    }
}
