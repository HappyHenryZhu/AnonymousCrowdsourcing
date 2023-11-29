const Pedersen = artifacts.require("Pedersen");
const SafeMath = artifacts.require("SafeMath");
const Utils = artifacts.require("Utils");
const ZeroCoin = artifacts.require("ZeroCoin");
const AnonymousCrowdsourcing = artifacts.require("AnonymousCrowdsourcing");

module.exports = function (deployer, network, accounts) {
    deployer.then(async () => {
        await deployer.deploy(SafeMath);
        await deployer.link(SafeMath, [Utils, Pedersen, ZeroCoin, AnonymousCrowdsourcing]);

        await deployer.deploy(Utils);
        await deployer.link(Utils, [Pedersen, ZeroCoin, AnonymousCrowdsourcing]);

        await deployer.deploy(Pedersen, "2090583907", "642996076579571851939547582363769362446679167969816015137470108219624530351", "29645808988800697353566862307331691561207478437311896149463650348773872465515", "1173792922");

        var ZeroCoinAddr = await deployer.deploy(ZeroCoin);
        await deployer.deploy(AnonymousCrowdsourcing, "1", "60", "60", ZeroCoinAddr.address, { from: accounts[0], value: "5000000000000000000"});//sent 5 ethers
    });
};