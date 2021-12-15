// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./IGameLoot.sol";
import "./Base64.sol";

abstract contract GameLoot is ERC721, IGameLoot {
    struct AttributeBaseData {
        uint8 decimal;
        bool exist;
    }

    struct AttributeData {
        uint128 attrID;
        uint128 attrValue;
    }

    // attrID => decimal
    mapping(uint128 => AttributeBaseData) internal _attrBaseData;
    // tokenID => attribute data
    mapping(uint256 => AttributeData[]) internal _attrData;

    uint256 internal _cap;

    event CreateAttribute(uint128 attrID, uint8 decimal);
    event CreateAttributeBatch(uint128[] attrIDs, uint8[] decimals);
    event AttributeChanged(uint256 tokenID);

    constructor(string memory name_, string memory symbol_, uint256 cap_) ERC721(name_, symbol_) {
        _cap = cap_;
    }

    function attributeDecimals(uint128 _attrID) public override virtual view returns (uint8) {
        return _attrBaseData[_attrID].decimal;
    }

    function attributes(uint256 _tokenID) public virtual view returns (AttributeData[] memory) {
        return _attrData[_tokenID];
    }

    function create(uint128 _id, uint8 _decimal) public override virtual {
        _create(_id, _decimal);
    }

    function createBatch(uint128[] memory _ids, uint8[] memory _decimals) public override virtual {
        _createBatch(_ids, _decimals);
    }

    function _create(uint128 _attrID, uint8 _decimal) internal virtual {
        _attrBaseData[_attrID] = AttributeBaseData(_decimal, true);
        emit CreateAttribute(_attrID, _decimal);
    }

    function _createBatch(uint128[] memory _attrIDs, uint8[] memory _decimals) internal virtual {
        require(_attrIDs.length == _decimals.length, "GameLoot: param length error");
        for (uint256 i; i < _attrIDs.length; i++) {
            _attrBaseData[_attrIDs[i]] = AttributeBaseData(_decimals[i], true);
        }
        emit CreateAttributeBatch(_attrIDs, _decimals);
    }

    function _attach(uint256 tokenID, uint128 attrID, uint128 value) internal virtual {
        require(_attrBaseData[attrID].exist, "GameLoot: attribute is not existed");
        require(_attrData[tokenID].length + 1 <= _cap, "GameLoot: too many attributes");
        _attrData[tokenID].push(AttributeData(attrID, value));
        emit AttributeChanged(tokenID);
    }

    function _attachBatch(uint256 tokenID, uint128[] memory attrIDs, uint128[] memory values) internal virtual {
        require(_attrData[tokenID].length + attrIDs.length <= _cap, "GameLoot: too many attributes");
        for (uint256 i; i < attrIDs.length; i++) {
            require(_attrBaseData[attrIDs[i]].exist, "GameLoot: attribute is not existed");
            _attrData[tokenID].push(AttributeData(attrIDs[i], values[i]));
        }
        emit AttributeChanged(tokenID);
    }

    function _update(uint256 tokenID, uint256 attrIndex, uint128 value) internal virtual {
        _attrData[tokenID][attrIndex].attrValue = value;
        emit AttributeChanged(tokenID);
    }

    function _updateBatch(uint256 tokenID, uint256[] memory attrIndexes, uint128[] memory values) internal virtual {
        for (uint256 i; i < attrIndexes.length; i++) {
            _attrData[tokenID][attrIndexes[i]].attrValue = values[i];
        }
        emit AttributeChanged(tokenID);
    }

    function _remove(uint256 tokenID, uint256 attrIndex) internal virtual {
        _attrData[tokenID][attrIndex] = _attrData[tokenID][_attrData[tokenID].length - 1];
        _attrData[tokenID].pop();
        emit AttributeChanged(tokenID);
    }

    function _removeBatch(uint256 tokenID, uint256[] memory attrIndexes) internal virtual {
        for (uint256 i; i < attrIndexes.length; i++) {
            _attrData[tokenID][attrIndexes[i]] = _attrData[tokenID][_attrData[tokenID].length - 1];
            _attrData[tokenID].pop();
        }
        emit AttributeChanged(tokenID);
    }

    function getCap() public view returns (uint256){
        return _cap;
    }

    function tokenURI(uint256 tokenID) override public view returns (string memory) {
        AttributeData[] memory attrData = _attrData[tokenID];

        string memory output = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">';

        string memory p1 = '</text><text x="10" y="';
        string memory p2 = '</text><text x="100" y="';
        string memory p3 = '" class="base">';

        bytes memory tb;
        for (uint256 i; i < _attrData[tokenID].length; i++) {
            if (i == 0)
                tb = abi.encodePacked(tb, toString(attrData[i].attrID), p2, '20', p3, toString(attrData[i].attrValue));
            else
                tb = abi.encodePacked(tb, p1, toString(20 + 20 * i), p3,  toString(attrData[i].attrID), p2, toString(20 + 20 * i), p3, toString(attrData[i].attrValue));
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
