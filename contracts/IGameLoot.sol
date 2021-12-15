// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGameLoot {
    /**
     * @dev Returns the decimals places of the attribute.
     */
    function attributeDecimals(uint128 attrID) external view returns (uint8);

    /**
     * @dev Create new attribute.
     */
    function create(uint128 attrID, uint8 decimals) external;

    /**
     * @dev Create a batch of new attributes.
     */
    function createBatch(uint128[] memory attrIDs, uint8[] memory decimals) external;

    /**
     * @dev Attach the attribute to NFT.
     */
    function attach(uint256 tokenID, uint128 attrID, uint128 value) external;

    /**
     * @dev Attach a batch of attributes to NFT.
     */
    function attachBatch(uint256 tokenID, uint128[] memory attrIDs, uint128[] memory values) external;

    /**
     * @dev Update the attribute to NFT.
     */
    function update(uint256 tokenID, uint256 attrIndex, uint128 value) external;

    /**
     * @dev Update a batch of attributes to NFT.
     */
    function updateBatch(uint256 tokenID, uint256[] memory attrIndexes, uint128[] memory values) external;

    /**
     * @dev Remove the attribute from NFT.
     */
    function remove(uint256 tokenID, uint256 attrIndex) external;

    /**
     * @dev Remove a batch of attributes from NFT.
     */
    function removeBatch(uint256 tokenID, uint256[] memory attrIndexes) external;
}
