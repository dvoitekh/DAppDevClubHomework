pragma solidity ^0.4.20;

import 'SimpleAuctionInterface.sol';

contract SimpleAuction is AuctionInterface {
    // containers
    enum Status { UNAVAILABLE, CREATED, COMPLETED, BUYED_IMMEDIATELY }

    struct Lot {
        string name;
        uint price;
        uint minBid;
        uint timestamp;
        address owner;
        uint lastBid;
        address lastBidOwner;
        uint createdAt;
        Status status;
    }

    struct Rating {
        uint positive;
        uint negative;
        bool exists;
    }

    // variables
    mapping (uint => Lot) private lots;
    mapping (address => Rating) private ratings;
    uint lotNonce = 0;

    // constants
    uint LOT_LIFETIME = 60;
    uint MAX_RATE = 5;

    // modifiers
    modifier createdLot(uint lotID) {
        require(lots[lotID].status == Status.CREATED);
        require(!isEnded(lotID));
        _;
    }

    modifier completedLot(uint lotID) {
        require(lots[lotID].status == Status.COMPLETED);
        _;
    }

    modifier validBid(uint lotID) {
        require(lots[lotID].minBid <= msg.value && lots[lotID].lastBid < msg.value);
        _;
    }

    modifier lotReadyForProcessing(uint lotID) {
        require(lots[lotID].status == Status.CREATED || lots[lotID].status == Status.BUYED_IMMEDIATELY);
        require(isEnded(lotID));
        _;
    }

    modifier lotRemovable(uint lotID) {
        require(lots[lotID].lastBid == 0);
        require(isEnded(lotID));
        _;
    }

    // functions
    function createLot(string name, uint price, uint minBid) external returns (uint) {
        lotNonce++;
        lots[lotNonce] = Lot(name, price, minBid, block.timestamp, msg.sender, 0, msg.sender, now, Status.CREATED);
        return lotNonce;
    }

    function removeLot(uint lotID) lotRemovable(lotID) {
        delete lots[lotID];
    }

    function bid(uint lotID) external payable createdLot(lotID) validBid(lotID) returns (uint) {
        lots[lotID].lastBidOwner.transfer(lots[lotID].lastBid);
        lots[lotID].lastBid = msg.value;
        lots[lotID].lastBidOwner = msg.sender;
        if (lots[lotID].price <= msg.value) {
            lots[lotID].status = Status.BUYED_IMMEDIATELY;
        }
        return msg.value;
    }

    function processLot(uint lotID) lotReadyForProcessing(lotID) {
        if (lots[lotID].lastBid > 0) {
            lots[lotID].status = Status.COMPLETED;
            lots[lotID].owner.transfer(lots[lotID].lastBid);
        } else {
            removeLot(lotID);
        }
    }

    function getBidder(uint lotID) constant returns (address) {
        return lots[lotID].lastBidOwner;
    }

    function isEnded(uint lotID) constant returns (bool) {
        return now - lots[lotID].createdAt > LOT_LIFETIME;
    }

    function isProcessed(uint lotID) constant returns (bool) {
        return lots[lotID].status == Status.COMPLETED;
    }

    function exists(uint lotID) constant returns (bool) {
        return lots[lotID].status != Status.UNAVAILABLE;
    }

    function rate(uint lotID, bool option) external completedLot(lotID) {
        require(lots[lotID].lastBidOwner == msg.sender);
        address owner = lots[lotID].owner;
        if (!ratings[owner].exists) {
            ratings[owner] = Rating(0, 0, true);
        }
        if (option) {
            ratings[owner].positive += 1;
        } else {
            ratings[owner].negative += 1;
        }
    }

    function getRating(address owner) constant external returns (uint) {
        uint positive = ratings[owner].positive;
        uint negative = ratings[owner].negative;
        if (positive + negative == 0) {
            return 0;
        }
        return uint(MAX_RATE * positive / (positive + negative));
    }
}
