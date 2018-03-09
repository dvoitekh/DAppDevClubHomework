pragma solidity ^0.4.20;

contract SimpleAuction {
    struct Lot {
        string name;
        uint timestamp;
        address owner;
        uint lastBid;
    }

    mapping (uint => Lot) public lots;

    uint lotNonce = 0;

    function createLot(string name) external returns (uint) {
        lotNonce++;

        lots[lotNonce] = Lot(name, block.timestamp, msg.sender, 0);

        return lotNonce;
    }

    function bid(uint lotID) external payable returns (uint) {
        require(lotID <= lotNonce);
        require(lotID > 0);

        lots[lotID].lastBid = msg.value;

        return msg.value;
    }
}
