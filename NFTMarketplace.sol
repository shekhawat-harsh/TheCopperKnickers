//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "hardhat/console.sol"; // <== your framework here/
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract NFTMarketplace is ERC721URIStorage {
    address payable owner;

    uint minPriceArtistCanSet = 0.0136 ether; //2000 Rs for simplisity will change it later

    using Counters for Counters.Counter;

    Counters.Counter private tokenIDs;
    Counters.Counter private itemSold;

    constructor() ERC721("NFTMarketplace", "NFTM") {
        owner = payable(msg.sender);
    }

    struct ListedART {
        uint tokenID;
        address payable artist;
        address payable currentHolder;
        uint price;
        uint NoOfPosibleBuyers;
        bool islisted;
    }

    mapping(uint => ListedART) private tokenIDToListedART;

    // function getInitialCost() public view returns (uint256) {
    // return initialCost;
    // }

    function getLatestListedArtData() public view returns (ListedART memory) {
        uint ctid = tokenIDs.current();
        return tokenIDToListedART[ctid];
    }

    function getListedArtData(uint tid) public view returns (ListedART memory) {
        return tokenIDToListedART[tid];
    }

    function getCurrentTokenID() public view returns (uint) {
        return tokenIDs.current();
    }

    // --string tokenURI , uint price in  front end
    function createNFTofArt(
        string memory tokenURI,
        uint price,
        address payable artOwner,
        uint numOfFractionTodivideItInto
    ) public payable returns (uint) {
        require(msg.sender == owner, "You Don't have the access");
        require(price > minPriceArtistCanSet, "Minum Requirenments not met");

        tokenIDs.increment();
        uint CurrentTokenID = tokenIDs.current();

        _safeMint(artOwner, CurrentTokenID);
        //still figuring out adress of putting address of artist here and how do i split this in desired no of ownership

        _setTokenURI(CurrentTokenID, tokenURI);

        listThisArt(
            CurrentTokenID,
            artOwner,
            price,
            numOfFractionTodivideItInto
        );

        return CurrentTokenID;
    }

    function listThisArt(
        uint tokenID,
        address payable artOwner,
        uint price,
        uint noOfPosibleBuyers
    ) private {
        tokenIDToListedART[tokenID] = ListedART(
            tokenID,
            artOwner,
            artOwner,
            price,
            noOfPosibleBuyers,
            true
        );

        _transfer(msg.sender, address(this), tokenID);
    }

    function getAllListedArts() public view returns (ListedART[] memory) {
        uint ListedartCount = 0;
        for (uint i = 1; i <= tokenIDs.current(); i++) {
            if (tokenIDToListedART[i].islisted == true) {
                ListedartCount += 1;
            }
        }

        ListedART[] memory allPresentListedArts = new ListedART[](
            ListedartCount
        );
        uint currentIndex = 0;
        uint currentId;

        for (uint i = 0; i < ListedartCount; i++) {
            if (tokenIDToListedART[i + 1].islisted == true) {
                currentId = i + 1;
                ListedART storage currentArt = tokenIDToListedART[currentId];
                allPresentListedArts[currentIndex] = currentArt;
                currentIndex += 1;
            }
        }

        return allPresentListedArts;
    }

    function getAllArts() public view returns (ListedART[] memory) {
        uint artCount = tokenIDs.current();
        ListedART[] memory allPresentArts = new ListedART[](artCount);
        uint currentIndex = 0;
        uint currentId;

        for (uint i = 0; i < artCount; i++) {
            currentId = i + 1;
            ListedART storage currentArt = tokenIDToListedART[currentId];
            allPresentArts[currentIndex] = currentArt;
            currentIndex += 1;
        }
        //the array 'tokens' has the list of all NFTs in the marketplace
        return allPresentArts;
    }

    function myOwnedArt() public view returns (ListedART[] memory) {
        uint totalItemCount = tokenIDs.current();
        uint itemCount = 0;
        uint currentIndex = 0;
        uint currentId;

        for (uint i = 0; i < totalItemCount; i++) {
            if (tokenIDToListedART[i + 1].currentHolder == msg.sender) {
                itemCount += 1;
            }
        }

        ListedART[] memory items = new ListedART[](itemCount);

        for (uint i = 0; i < totalItemCount; i++) {
            if (tokenIDToListedART[i + 1].currentHolder == msg.sender) {
                currentId = i + 1;
                ListedART storage currentItem = tokenIDToListedART[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }

        return items;
    }

    function exicuteSaleOfArt(
        uint tID,
        uint pay,
        address payable buyersAddress
    ) public payable {
        require(pay == tokenIDToListedART[tID].price, "Send Appropiate Money");
        address payable artSeller = tokenIDToListedART[tID].currentHolder;

        // createNFTofArt(tokenURI, price, artOwner, numOfFractionTodivideItInto);
        _transfer(address(this), msg.sender, tID);
        approve(address(this), tID);

        tokenIDToListedART[tID].currentHolder = payable(buyersAddress);
        tokenIDToListedART[tID].islisted = false;
        itemSold.increment();
        payable(owner).transfer(pay);
        payable(artSeller).transfer((pay * 99) / 100); //paying 99percent of the money to the artist and keeping 1 percent of the money
    }

    function relistArt(uint tid, uint newPrice) public {
        require(
            tokenIDToListedART[tid].currentHolder == msg.sender,
            "You are not the holder of this nft"
        );
        require(newPrice >= minPriceArtistCanSet);
        require(tokenIDToListedART[tid].islisted == false);

        tokenIDToListedART[tid].price = newPrice;
        tokenIDToListedART[tid].islisted = true;
    }
}
