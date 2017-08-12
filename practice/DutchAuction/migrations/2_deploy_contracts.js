var DutchAuction = artifacts.require("./DutchAuction.sol");

module.exports = function(deployer) {
  deployer.deploy(DutchAuction, 8, 1, 2, 2, "0x5af110172e0dec11d94fce341c4313f017810f63");
};
