var HDWalletProvider = require("truffle-hdwallet-provider-privkey");

var infura_apikey = "AE6On73pYevJNjphqDyT";
var privkey = "87eb33c6746c117131992f34b6df13e7306b4fafd8afd72732bd861a0f780cec"

module.exports = {
    solc: {

    },
    networks: {
        development: {
            host: "localhost",
            port: 8545,
            network_id: "*", // Match any network id
            gas:   8000000,
           gasPrice: 20
        },
        coverage: {
            from:    '0x56216dcfece41f009f7f71237c2bad6783a67c41',
            host: "localhost",
            network_id: "*",
            port: 8545,         // <-- If you change this, also set the port option in .solcover.js.
            gas: 0xfffffffffff, // <-- Use this high gas value
            gasPrice: 1
        },
        
        ropsten: {
            provider: new HDWalletProvider(privkey, "https://ropsten.infura.io/"+infura_apikey),
            network_id: 3,
            gas: 4600000
        }
    }
};
