// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

error NFTMarketplace__InvalidListingAmount();
error NFTMarketplace__ListingAlreadyExists();
error NFTMarketplace__TokenNotApproved();
error NFTMarketplace__NotOwner();
error NFTMarketplace__ListingDoesNotExists();
error NFTMarketplace__IncorrectEthSupplied();

contract NFTMarketplace {
    struct Listing {
        uint256 price;
        address seller;
    }

    mapping(address => mapping(uint256 => Listing)) public listings;

    event ListingCreated(
        address indexed nftAddress,
        uint256 indexed tokenId,
        address indexed seller,
        uint256 price
    );

    event ListingCanceled(
        address indexed nftAddress,
        uint256 indexed tokenId,
        address indexed seller
    );

    event ListingUpdated(
        address indexed nftAddress,
        uint256 indexed tokenId,
        address indexed seller,
        uint256 newPrice
    );

    event ListingPurchased(
        address indexed nftAddress,
        uint256 indexed tokenId,
        address indexed buyer,
        address seller
    );

    modifier isNFTOwner(address nftAddress, uint256 tokenId) {
        if(IERC721(nftAddress).ownerOf(tokenId) != msg.sender) revert NFTMarketplace__NotOwner();
        _;
    }

    modifier isNotListed(address nftAddress, uint256 tokenId) {
        if(listings[nftAddress][tokenId].price != 0) revert NFTMarketplace__ListingAlreadyExists();
        _;
    }

    modifier isListed(address nftAddress, uint256 tokenId) {
        if(listings[nftAddress][tokenId].price <= 0) revert NFTMarketplace__ListingDoesNotExists();
        _;
    }

    function createListing(
        address nftAddress,
        uint256 tokenId,
        uint256 price
    ) external isNotListed(nftAddress, tokenId) isNFTOwner(nftAddress, tokenId) {
        // Cannot create a listing to sell NFT for <= 0 ETH
        require(price > 0, "MRKT: Price must be > 0");

        // Marketplace must be approved to transfer NFT
        IERC721 nftContract = IERC721(nftAddress);
        require(
            nftContract.isApprovedForAll(msg.sender, address(this)) ||
                nftContract.getApproved(tokenId) == address(this),
            "MRKT: No approval for NFT"
        );

        // Add listing to mapping
        listings[nftAddress][tokenId] = Listing({
            price: price,
            seller: msg.sender
        });

        // Emit the event
        emit ListingCreated(nftAddress, tokenId, msg.sender, price);
    }

    function cancelListing(address nftAddress, uint256 tokenId) external isListed(nftAddress, tokenId) isNFTOwner(nftAddress, tokenId) {
        delete listings[nftAddress][tokenId];

        emit ListingCanceled(nftAddress, tokenId, msg.sender);
    }

    function updateListing(address nftAddress, uint256 tokenId, uint256 newPrice) external isListed(nftAddress, tokenId) isNFTOwner(nftAddress, tokenId) {
        if(newPrice <= 0) revert NFTMarketplace__InvalidListingAmount();

        listings[nftAddress][tokenId].price = newPrice;

        emit ListingUpdated(nftAddress, tokenId, msg.sender, newPrice);
    }

    function purchaseListing(address nftAddress, uint256 tokenId) external payable isListed(nftAddress, tokenId) {
        Listing memory listing = listings[nftAddress][tokenId];

        if(msg.value != listing.price) revert NFTMarketplace__IncorrectEthSupplied();

        delete listings[nftAddress][tokenId];

        IERC721(nftAddress).safeTransferFrom(
            listing.seller,
            msg.sender,
            tokenId
        );

        payable(listing.seller).transfer(msg.value);

        emit ListingPurchased(nftAddress, tokenId, msg.sender, listing.seller);
    }
}