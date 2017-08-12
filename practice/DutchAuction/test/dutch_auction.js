var DutchAuction = artifacts.require("./DutchAuction.sol");

function createSleepPromise(timeout) {
    return new Promise(function(resolve) {
        setTimeout(resolve, timeout);
    });
};

function sleep(timeout) {
    // Pass value through, if used in a promise chain
    function promiseFunction(value) {
        return createSleepPromise(timeout).then(function() {
            return value;
        });
    };

    // Normal promise
    promiseFunction.then = function() {
        var sleepPromise = createSleepPromise(timeout);

        return sleepPromise.then.apply(sleepPromise, arguments);
    };
    promiseFunction.catch = Promise.resolve().catch;

    return promiseFunction;
}

contract('DutchAuction', function(accounts) {
    it("should create a new auction", function() {
        return DutchAuction.deployed().then(function(instance) {
            return instance.getOfferPrice.call();
        }).then(function(price) {
            assert.equal(price.valueOf(), 8, "offerPrice not setup correctly");
        });
    });

    it("should be sold on first bidding", function() {
        var auction;
        return DutchAuction.deployed().then(function(instance) {
            auction = instance;
            // console.log(auction);
            console.log("starting auction");
            return auction.startAuction();
        }).then(function() {
            console.log("auction started");
            return auction.getOfferPrice.call();
        }).then(function(price) {
            var offerPrice = price.toNumber();
            console.log("Offer Price: " + offerPrice);
            return auction.bid({from: accounts[5], value: web3.toWei(offerPrice+1, "ether")});
        }).then(function(result) {
            console.log(result);
            console.log("after bidding");
            for (var i = 0; i < result.logs.length; i++) {
                var log = result.logs[i];
                console.log(log.event);
                if (log.event == "BuyerFound") {
                    console.log("Buyer Found !!!!");
                }
            }
        }).then(function() {
            return auction.endAuction();
        }).then(function(auctionResult) {
            for (var i = 0; i < auctionResult.logs.length; i++) {
                var log = auctionResult.logs[i];
                if (log == "AuctionEnded") {
                    console.log("Auction Ended");
                    console.log(log);
                }
            }
        });
    });

    // it("should be sold after second bidding", function() {
    //     var auction;
    //     return DutchAuction.deployed().then(function(instance) {
    //         auction = instance;
    //         console.log("starting auction");
    //         return auction.startAuction();
    //     }).then(sleep(3000))
    //     .then(function() {
    //         console.log("decreasing Offer");
    //         return auction.decreaseOfferPrice();
    //     }).then(sleep(3000))
    //     .then(function() {
    //         console.log("decreasing Offer");
    //         return auction.decreaseOfferPrice();
    //     }).then(function() {
    //         return auction.getOfferPrice.call();
    //     // }).then(function(price) {
    //     //     // price = price.toNumber();
    //     //     console.log(price);
    //     //     return price
    //     }).then(function(price) {
    //         console.log("Offer Price: ")
    //         console.log(price)
    //         return auction.bid({from: accounts[1], value: price+1});
    //     }).then(function(result) {
    //         console.log("after bidding");
    //         for (var i = 0; i < result.logs.length; i++) {
    //             var log = result.logs[i];
    //             if (log.event == "BuyerFound") {
    //                 console.log("Buyer Found !!!!");
    //             }
    //         }
    //     }).then(function() {
    //         return auction.endAuction();
    //     }).then(function(auctionResult) {
    //         for (var i = 0; i < auctionResult.logs.length; i++) {
    //             var log = auctionResult.logs[i];
    //             if (log == "AuctionEnded") {
    //                 console.log("Auction Ended");
    //                 console.log(log);
    //             }
    //         }
    //     });
    // });

});
