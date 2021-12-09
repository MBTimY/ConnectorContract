pragma solidity ^0.8.0;

interface IGameLoot {
    /**
     * @dev Returns the decimals places of the attribute.
     */
    function attributeDecimals(uint256 attrID) external view returns (uint8);

    /**
     * @dev Returns all attributes' value of the tokenID.
     */
    function attributes(uint256 tokenID) external view returns (uint256[] memory, uint256[] memory);

    /**
     * @dev Create new attribute.
     */
    function create(uint256 id, uint8 decimals) external;

    /**
     * @dev Create a batch of new attributes.
     */
    function createBatch(uint256[] memory ids, uint8[] memory decimals) external;

    /**
     * @dev Attach the attribute to NFT.
     */
    function attach(uint256 tokenID, uint256 attrID, uint256 value) external;

    /**
     * @dev Attach a batch of attributes to NFT.
     */
    function attachBatch(uint256 tokenID, uint256[] memory attrIDs, uint256[] memory values) external;

    /**
     * @dev Update the attribute to NFT.
     */
    function update(uint256 tokenID, uint256 attrIndex, uint256 value) external;

    /**
     * @dev Update a batch of attributes to NFT.
     */
    function updateBatch(uint256 tokenID, uint256[] memory attrIndexes, uint256[] memory values) external;

    /**
     * @dev Remove the attribute from NFT.
     */
    function remove(uint256 tokenID, uint256 attrID) external;

    /**
     * @dev Remove a batch of attributes from NFT.
     */
    function removeBatch(uint256 tokenID, uint256[] memory attrIDs) external;
}
