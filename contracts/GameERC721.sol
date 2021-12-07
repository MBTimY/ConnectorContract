pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./IGameERC721.sol";

contract GameERC721 is ERC721, IGameERC721 {
    struct AttributeBaseData {
        uint8 decimal;
        bool exist;
    }
    // attrID => decimal
    mapping(uint256 => AttributeBaseData) internal _attrData;
    // tokenID => attrID => value
    mapping(uint256 => mapping(uint256 => uint256)) internal _attrValues;

    event CreateAttribute(uint256 attrID, uint8 decimal);
    event CreateAttributeBatch(uint256[] attrIDs, uint8[] decimals);
    event AttachAttribute(uint256 tokenID, uint256 attrID, uint256 value);
    event AttachAttributeBatch(uint256 tokenID, uint256[] attrIDs, uint256[] values);
    event RemoveAttribute(uint256 tokenID, uint256 attrID);
    event RemoveAttributeBatch(uint256 tokenID, uint256[] attrIDs);

    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {}

    function attributeDecimals(uint256 _attrID) public override virtual view returns (uint8) {
        return _attrData[_attrID].decimal;
    }

    function attributeValue(uint256 _tokenID, uint256 _attrID) public override virtual view returns (uint256) {
        return _attrValues[_tokenID][_attrID];
    }

    function create(uint256 _id, uint8 _decimal) public override virtual {
        _create(_id, _decimal);
    }

    function createBatch(uint256[] memory _ids, uint8[] memory _decimals) public override virtual {
        _createBatch(_ids, _decimals);
    }

    function attach(uint256 _tokenID, uint256 _attrID, uint256 _value) public override virtual {
        _attach(_tokenID, _attrID, _value);
    }

    function attachBatch(uint256 _tokenID, uint256[] memory _attrIDs, uint256[] memory _values) public override virtual {
        _attachBatch(_tokenID, _attrIDs, _values);
    }

    function remove(uint256 _tokenID, uint256 _attrID) public override virtual {
        _remove(_tokenID, _attrID);
    }

    function removeBatch(uint256 _tokenID, uint256[] memory _attrIDs) public override virtual {
        _removeBatch(_tokenID, _attrIDs);
    }

    function _create(uint256 _id, uint8 _decimal) internal virtual {
        _attrData[_id] = AttributeBaseData(_decimal, true);
        emit CreateAttribute(_id, _decimal);
    }

    function _createBatch(uint256[] memory _ids, uint8[] memory _decimals) internal virtual {
        require(_ids.length == _decimals.length, "GameERC721: param length error");
        for (uint256 i; i < _ids.length; i++) {
            _attrData[_ids[i]] = AttributeBaseData(_decimals[i], true);
        }
        emit CreateAttributeBatch(_ids, _decimals);
    }

    function _attach(uint256 _tokenID, uint256 _attrID, uint256 _value) internal virtual {
        require(_attrData[_attrID].exist, "GameERC721: attribute is not existed");
        _attrValues[_tokenID][_attrID] = _value;
        emit AttachAttribute(_tokenID, _attrID, _value);
    }

    function _attachBatch(uint256 _tokenID, uint256[] memory _attrIDs, uint256[] memory _values) internal virtual {
        require(_attrIDs.length == _values.length, "GameERC721: param length error");
        for (uint256 i; i < _attrIDs.length; i++) {
            require(_attrData[_attrIDs[i]].exist, "GameERC721: attribute is not existed");
            _attrValues[_tokenID][_attrIDs[i]] = _values[i];
        }
        emit AttachAttributeBatch(_tokenID, _attrIDs, _values);
    }

    function _remove(uint256 _tokenID, uint256 _attrID) internal virtual {
        _attrValues[_tokenID][_attrID] = 0;
        emit RemoveAttribute(_tokenID, _attrID);
    }

    function _removeBatch(uint256 _tokenID, uint256[] memory _attrIDs) internal virtual {
        for (uint256 i; i < _attrIDs.length; i++) {
            _attrValues[_tokenID][_attrIDs[i]] = 0;
        }
        emit RemoveAttributeBatch(_tokenID, _attrIDs);
    }
}
