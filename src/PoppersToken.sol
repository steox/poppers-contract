// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin/contracts/access/Ownable.sol";
import "openzeppelin/contracts/security/ReentrancyGuard.sol";
import "openzeppelin/contracts/token/ERC20/IERC20.sol";
import "openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin/contracts/token/ERC721/ERC721.sol";
import "openzeppelin/contracts/utils/Address.sol";
import "openzeppelin/contracts/utils/Strings.sol";

contract Poppers is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    constructor() {}

    /* VIEWS */

    /* ADMIN */

    /* INTERNALS */

    /* RECOVERY */

    function recoverFunds() external onlyOwner nonReentrant {
        (bool success,) = msg.sender.call{value: address(this).balance}("");
        if (!success) revert();
    }

    function recoverERC20(address tokenAddress) external onlyOwner nonReentrant {
        IERC20 token = IERC20(tokenAddress);
        _recoverERC20(token);
    }

    function _recoverERC20(IERC20 token) internal {
        token.safeTransfer(msg.sender, token.balanceOf(address(this)));
    }
}
