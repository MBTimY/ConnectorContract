pragma solidity ^0.8.0;

interface IGameERC721 {
    /**
     * @dev Returns the decimals places of the attribute.
     */
    function attributeDecimals(uint256 _attrID) external view returns (uint8);

    /**
     * @dev Returns the value of the attribute.
     */
    function attributeValue(uint256 _tokenID, uint256 _attrID) external view returns (uint256);

    /**
     * @dev Create new attribute.
     */
    function create(uint256 _id, uint8 _decimals) external;

    /**
     * @dev Create a batch of new attributes.
     */
    function createBatch(uint256[] memory _ids, uint8[] memory _decimals) external;

    /**
     * @dev Attach the attribute to NFT.
     */
    function attach(uint256 _tokenID, uint256 _attrID, uint256 _value) external;

    /**
     * @dev Attach a batch of attributes to NFT.
     */
    function attachBatch(uint256 _tokenID, uint256[] memory _attrIDs, uint256[] memory _values) external;

    /**
     * @dev Remove the attribute from NFT.
     */
    function remove(uint256 _tokenID, uint256 _attrID) external;

    /**
     * @dev Remove a batch of attributes from NFT.
     */
    function removeBatch(uint256 _tokenID, uint256[] memory _attrIDs) external;
}
