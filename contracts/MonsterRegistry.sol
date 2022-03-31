// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "./Struct.sol";
import "./Base64.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MonsterRegistry is Ownable {

    //  attribute id => attribute name
    mapping(uint256 => string) public attrMetadata;

    function fill(AttrMetadataStruct[] memory metadata) external onlyOwner {
        for (uint256 i; i < metadata.length; i++) {
            attrMetadata[metadata[i].attrID] = metadata[i].name;
        }
    }

    function update(uint256 attrID, string memory name) external onlyOwner {
        attrMetadata[attrID] = name;
    }

    function tokenURI(uint256 tokenID, AttributeData[] memory attrData) public pure returns (string memory) {
        string memory output = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">ID</text><text x="80" y="20" class="base">Value</text><text x="185" y="20" class="base">ID</text><text x="255" y="20" class="base">Value';

        string memory p1 = '</text><text x="10" y="';
        string memory p2 = '</text><text x="80" y="';
        string memory p3 = '</text><text x="185" y="';
        string memory p4 = '</text><text x="255" y="';
        string memory p5 = '" class="base">';

        bytes memory tb;
        for (uint256 i; i < attrData.length; i++) {
            uint128 id = attrData[i].attrID;
            uint128 value = attrData[i].attrValue;
            if (i % 2 == 0) {
                string memory y = toString(40 + 20 * i / 2);
                tb = abi.encodePacked(tb, p1, y, p5, toString(id), p2, y, p5, toString(value));
            } else {
                string memory y = toString(40 + 20 * (i - 1) / 2);
                tb = abi.encodePacked(tb, p3, y, p5, toString(id), p4, y, p5, toString(value));
            }
        }
        tb = abi.encodePacked(tb, '</text></svg>');

        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Bag #', toString(tokenID),
            '", "description": "GameLoot is a general NFT for games. Images, attribute name and other functionality are intentionally omitted for each game to interprets. You can use gameLoot as you like in a variety of games.", "image": "data:image/svg+xml;base64,',
            Base64.encode(abi.encodePacked(output, tb)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

}
