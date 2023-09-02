// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin/contracts/access/Ownable.sol";
import "openzeppelin/contracts/security/ReentrancyGuard.sol";
import "openzeppelin/contracts/token/ERC20/IERC20.sol";
import "openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin/contracts/token/ERC721/ERC721.sol";
import "openzeppelin/contracts/utils/Address.sol";
import "openzeppelin/contracts/utils/Strings.sol";

contract Poppers is ERC721, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Strings for uint256;
    using Address for address;

    string public constant PREREVEAL_URI = "ipfs://bafkreibwtwzchmyfru4xxaepdz4gwk3r6pq52ugvo5uenb6vtt4wfmksb4";

    uint256 public immutable MAX_SUPPLY;
    uint256 public immutable PRICE;
    uint256 public immutable MAX_MINT;
    uint256 public immutable MIN_PEPE;
    uint256 public immutable BURN_PERCENT; // Out of 100

    string private $baseURI;
    uint256 private $tokenIds;
    // bool public $sale;
    uint256 private $saleTimestamp;

    mapping(address => uint256) public $mintCount;
    mapping(address => uint256) public $freeMint;

    error NotSale();
    error NotEligible();
    error OnlyEOA();
    error MaxSupplyReached();
    error InsufficientFunds();

    constructor(
        uint256 maxSupply,
        uint256 price,
        uint256 maxMint,
        uint256 minPEPE,
        uint256 burnPercent,
        string memory name,
        string memory symbol
    ) ERC721(name, symbol) {
        if (burnPercent > 100) revert();

        MAX_SUPPLY = maxSupply;
        PRICE = price;
        MAX_MINT = maxMint;
        MIN_PEPE = minPEPE;
        BURN_PERCENT = burnPercent;

        $saleTimestamp = type(uint256).max;

        _mintTeam();
    }

    /* VIEWS */

    function sale() public view returns (bool) {
        return ($saleTimestamp < block.timestamp);
    }

    function currentSupply() external view returns (uint256) {
        return $tokenIds;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : PREREVEAL_URI;
    }

    function isEligible(address user) external view returns (bool) {
        return _isEligible(user);
    }

    /* ADMIN */

    function setBaseURI(string calldata baseURI) external onlyOwner {
        $baseURI = baseURI;
    }

    // function switchSale() external onlyOwner {
    //     $sale = true;
    // }

    // function killSale() external onlyOwner {
    //     delete $sale;
    // }

    function setSale(uint256 timestamp) external onlyOwner {
        $saleTimestamp = timestamp;
    }

    /* PUBLIC */

    function mint() external payable nonReentrant {
        address user = msg.sender;

        if (!_isEligible(user)) revert NotEligible();

        if (!sale()) revert NotSale();
        if (user.isContract()) revert OnlyEOA();

        if ($freeMint[user] == 0) {
            if (PRICE > msg.value) revert InsufficientFunds();
            /* BURN */
            _distributePEPE(PRICE);
        } else {
            --$freeMint[user];
        }

        /* MINT */
        ++$mintCount[user];
        uint256 tokenIds = $tokenIds++;

        if (tokenIds > MAX_SUPPLY - 1) revert MaxSupplyReached();
        _mint(user, tokenIds);
    }

    function addFreeMint(address addr) external onlyOwner {
        ++$freeMint[addr];
    }

    /* INTERNALS */

    function _distributePEPE(uint256 amount) internal {
        uint256 _value = ((amount * BURN_PERCENT) / 100);
        // uint256 _id = _random(tokenId);
        // address beneficiary = _ownerOf(_id);

        (bool success,) = address(0).call{value: _value}("");
        if (!success) revert();
    }

    // function _random(uint256 tokenId) internal view returns (uint256) {
    //     // psudo-random
    //     return uint256(keccak256(abi.encodePacked(tx.origin, blockhash(block.number - 1), block.timestamp)))
    //         % (tokenId + 1);
    // }

    function _baseURI() internal view virtual override returns (string memory) {
        return $baseURI;
    }

    function _isEligible(address sender) internal view returns (bool) {
        return !(sender.balance < MIN_PEPE || $mintCount[sender] > (MAX_MINT - 1));
    }

    function _mintTeam() internal {
        _mint(0xc7d48f75E1C4B3f2B97A57Fd925d9c2388F844EF, 0);
        _mint(0x954D61Cf1f5F06722fD178F39a125E4d4130d29e, 1);
        _mint(0xc7d48f75E1C4B3f2B97A57Fd925d9c2388F844EF, 2);
        $tokenIds = 3;
    }

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
