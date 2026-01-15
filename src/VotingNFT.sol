// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract VotingNFT is ERC721, Ownable {
    uint256 private _tokenIds;

    constructor() ERC721("VotingNFT", "VOTE")Ownable(msg.sender) {}

    function mint(address to) external onlyOwner  {
        _safeMint(to, _tokenIds);
        _tokenIds++;
    }
}