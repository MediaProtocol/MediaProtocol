var MediaToken = artifacts.require("MediaToken");
var MediaManager = artifacts.require("MediaManager");
var IdentityVerificationDispatcher = artifacts.require("IdentityVerificationDispatcher");
var IdentityVerification = artifacts.require("IdentityVerification");
var IdentityVerificationImplementation = artifacts.require("IdentityVerificationImplementation");
var Promotions = artifacts.require("Promotions");
var PromotionsDispatcher = artifacts.require("PromotionsDispatcher");
var PromotionsImplementation = artifacts.require("PromotionsImplementation");
var Promotion = artifacts.require("Promotion");
var promotionLibrary = artifacts.require("promotionLibrary");
var SubscriptionManagerImplementation = artifacts.require("SubscriptionManagerImplementation");
var subscriptionManagerLibrary = artifacts.require("subscriptionManagerLibrary");
var SimpleSubscriptionDefinition = artifacts.require("SimpleSubscriptionDefinition");

module.exports = function(deployer) {
//   deployer.deploy(MediaToken, 1000000000000000000000000);
   deployer.deploy(IdentityVerificationImplementation).then(function() {
        return deployer.deploy(IdentityVerificationDispatcher, IdentityVerificationImplementation.address);
    });//*/
   deployer.deploy(promotionLibrary);
   deployer.deploy(subscriptionManagerLibrary);
   deployer.link(subscriptionManagerLibrary, PromotionsImplementation);
   deployer.link(promotionLibrary, Promotion);
   deployer.link(promotionLibrary, PromotionsImplementation);
   deployer.deploy(PromotionsImplementation).then(function() {
       return deployer.deploy(PromotionsDispatcher, PromotionsImplementation.address, "0x096C7cf7665daCf1668997d1e3cafc2dDd96D1B0");
   });
   //deployer.deploy(SimpleSubscriptionDefinition);
};


