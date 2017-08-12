pragma solidity ^0.4.10;

contract DutchAuction {

    address public beneficiary;
    address public auctioneer;
    uint public biddingStart;
    uint public biddingDuration;
    bool biddingStarted;

    uint public offerPrice;
    uint public priceDecrement;
    uint public minPrice;
    uint public highestBid;
    address public highestBidder;

    enum State {active, transaction, inactive, ended}
    State public state;

    mapping(address => uint) pendingReturns;

    event NewOfferPrice(uint amount);
    event BuyerFound();
    event bidding();
    event AuctionEnded(address winner, uint amount);

    modifier onlyAuctioneer() {require(msg.sender == auctioneer); _;}
    modifier inState(State _state) {require(state == _state); _;}

    function DutchAuction (uint startPrice, uint _priceDecrement, uint _minPrice, uint _biddingDuration, address _beneficiary) {
        auctioneer = msg.sender;
        offerPrice = startPrice;
        priceDecrement =_priceDecrement;
        minPrice = _minPrice;
        biddingDuration = _biddingDuration;
        beneficiary = _beneficiary;
        state = State.inactive;
        biddingStarted = false;
    }

    function getOfferPrice()
        returns (uint)
    {
        return offerPrice;
    }

    function startAuction()
        onlyAuctioneer
        /*inState(State.active)*/
    {
        state = State.active;
        biddingStart = now;
        /*while (now - biddingStart < biddingDuration && state == State.active) {}
        while (state == State.active && offerPrice >= minPrice + priceDecrement) {
            offerPrice = offerPrice - priceDecrement;
            NewOfferPrice(offerPrice);
            biddingStart = now;
            while (now - biddingStart < biddingDuration && state == State.active) {}
            //while (state == State.transaction);
        }
        if (state != State.ended) state = State.inactive;*/
    }

    function decreaseOfferPrice()
        onlyAuctioneer
        inState(State.active)
    {
        if (now - biddingStart > biddingDuration) {
            offerPrice = offerPrice - priceDecrement;
            NewOfferPrice(offerPrice);
            biddingStart = now;
        }
    }

    function bid()
        payable
        inState(State.active)
    {
        bidding;
        var amount = offerPrice;
        require(msg.value > amount);
        /*state = State.transaction;*/
        state = State.inactive;
        pendingReturns[highestBidder] = msg.value - amount;
        highestBidder = msg.sender;
        highestBid = amount;
        BuyerFound;
    }

    function withdraw() returns (bool) {
        var amount = pendingReturns[msg.sender];
        if (amount > 0) {
            pendingReturns[msg.sender] = 0;
            if (!msg.sender.send(amount)) {
                pendingReturns[msg.sender] = amount;
                return false;
            }
        }
        return true;
    }

    function endAuction()
        onlyAuctioneer
    {
        require(state != State.ended);
        state = State.ended;
        if (highestBidder != 0) {
            AuctionEnded(highestBidder, highestBid);
            beneficiary.transfer(highestBid);
        }
    }
}
