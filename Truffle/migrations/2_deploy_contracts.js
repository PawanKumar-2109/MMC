var mmctoken = artifacts.require("mmctoken")

module.exports = function(deployer) {
	deployer.deploy(mmctoken,10000);
};