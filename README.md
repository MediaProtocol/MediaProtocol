# Getting started

Install dependencies and Truffle:

```
yarn global add truffle
yarn install
```

Inside source directory, install zeppelin solidity library:
```
npm init
npm install zeppelin-solidity
```

Ropsten network uses the mnemonic defined in truffle.js. This must correspond with the mnemonic set in MetaMask, and the account must have an Ethereum balance. Then run:

```yarn run migrate```

# Updates

## Contract source

- Copy updated json to ccserver/src/main/resources/contracts
- Run update_contracts.sh in ccserver folder  

- Copy to ccapp/assets/contracts/MediaCoin.json

- Update ABI in publisher-portal/.../Publish.js

## Contract address

- Update ccapp/assets/config/config.json
- Update ccserver/src/main/scala/ccserver/service/blockchain/BlockchainAdapter.scala
- Update publisher-portal/.../Publish.js
