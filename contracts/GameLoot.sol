pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./IGameLoot.sol";
import "./Base64.sol";

abstract contract GameLoot is ERC721, IGameLoot {
    struct AttributeBaseData {
        uint8 decimal;
        bool exist;
    }
    // attrID => decimal
    mapping(uint256 => AttributeBaseData) internal _attrData;
    // tokenID => values
    mapping(uint256 => uint256[]) internal _attrValues;
    // tokenID => attribute ids
    mapping(uint256 => uint256[]) internal _attrIDs;

    uint256 internal _cap;

    event CreateAttribute(uint256 attrID, uint8 decimal);
    event CreateAttributeBatch(uint256[] attrIDs, uint8[] decimals);

    constructor(string memory name_, string memory symbol_, uint256 cap_) ERC721(name_, symbol_) {
        _cap = cap_;
    }

    function attributeDecimals(uint256 _attrID) public override virtual view returns (uint8) {
        return _attrData[_attrID].decimal;
    }

    function attributes(uint256 _tokenID) public override virtual view returns (uint256[] memory, uint256[] memory) {
        return (_attrIDs[_tokenID], _attrValues[_tokenID]);
    }

    function create(uint256 _id, uint8 _decimal) public override virtual {
        _create(_id, _decimal);
    }

    function createBatch(uint256[] memory _ids, uint8[] memory _decimals) public override virtual {
        _createBatch(_ids, _decimals);
    }

    function _create(uint256 _id, uint8 _decimal) internal virtual {
        _attrData[_id] = AttributeBaseData(_decimal, true);
        emit CreateAttribute(_id, _decimal);
    }

    function _createBatch(uint256[] memory _ids, uint8[] memory _decimals) internal virtual {
        require(_ids.length == _decimals.length, "GameLoot: param length error");
        for (uint256 i; i < _ids.length; i++) {
            _attrData[_ids[i]] = AttributeBaseData(_decimals[i], true);
        }
        emit CreateAttributeBatch(_ids, _decimals);
    }

    function _attach(uint256 tokenID, uint256 attrID, uint256 value) internal virtual {
        require(_attrData[attrID].exist, "GameLoot: attribute is not existed");
        if (_attrIDs[tokenID].length + 1 > _cap) {
            _clear(tokenID);
        }
        _attrIDs[tokenID].push(attrID);
        _attrValues[tokenID].push(value);
    }

    function _attachBatch(uint256 tokenID, uint256[] memory attrIDs, uint256[] memory values) internal virtual {
        if (_attrIDs[tokenID].length + attrIDs.length > _cap) {
            _clear(tokenID);
        }
        require(_attrIDs[tokenID].length + attrIDs.length <= _cap, "GameLoot: too many attributes");
        for (uint256 i; i < attrIDs.length; i++) {
            require(_attrData[attrIDs[i]].exist, "GameLoot: attribute is not existed");
            _attrIDs[tokenID].push(attrIDs[i]);
            _attrValues[tokenID].push(values[i]);
        }
    }

    function _update(uint256 tokenID, uint256 attrIndex, uint256 value) internal virtual {
        _attrValues[tokenID][attrIndex] = value;
    }

    function _updateBatch(uint256 tokenID, uint256[] memory attrIndexes, uint256[] memory values) internal virtual {
        for (uint256 i; i < attrIndexes.length; i++) {
            _attrValues[tokenID][attrIndexes[i]] = values[i];
        }
    }

    function _remove(uint256 tokenID, uint256 attrIndex) internal virtual {
        delete _attrValues[tokenID][attrIndex];
    }

    function _removeBatch(uint256 tokenID, uint256[] memory attrIndexes) internal virtual {
        for (uint256 i; i < attrIndexes.length; i++) {
            delete _attrValues[tokenID][attrIndexes[i]];
        }
    }

    function _clear(uint256 tokenID) internal virtual {
        for (uint256 i; i < _attrIDs[tokenID].length; i++) {
            if (_attrValues[tokenID][i] == 0) {
                _attrValues[tokenID][i] = _attrValues[tokenID][_attrValues[tokenID].length - 1];
                _attrIDs[tokenID][i] = _attrIDs[tokenID][_attrIDs[tokenID].length - 1];
                _attrValues[tokenID].pop();
                _attrIDs[tokenID].pop();
            }
        }
    }

    function tokenURI(uint256 tokenID) override public view returns (string memory) {
        string memory output = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="{{$x}}" y="{{$y}}" class="base">{{$attr}}</text></svg>';
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Bag #', toString(tokenID), '", "description": "GameLoot is a general NFT for games. Images, attribute name and other functionality are intentionally omitted for each game to interprets. You can use gameLoot as you like in a variety of games.", "image": "data:image/svg+xml;base64,', Base64.encode(abi.encode(output, _attrIDs[tokenID], _attrValues[tokenID])), '"}'))));
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
