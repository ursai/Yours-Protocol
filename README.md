# eth-PE

## test
- python3 <= 3.10.9
- [brownie](https://eth-brownie.readthedocs.io/en/stable/index.html)
  ```shell
  pip install brownie
  ```

- [ganache](https://github.com/trufflesuite/ganache)
  ```shell
  npm install ganache --global
  ```

- run test
  ```shell
  brownie test
  ```

## demo
```shell
brownie run demo
```

## deploy
- set variables in _.env_ file

- use brownie to deploy and verify source code on etherscan
  ```shell
  brownie run deploy [--network [sepolia]]
  ```

## deployed contracts on sepolia
- [0x3beeCD6b0a00Ff86ba6a3bE69C35c4Dd24B5e82E](https://sepolia.etherscan.io/address/0x3beeCD6b0a00Ff86ba6a3bE69C35c4Dd24B5e82E#code)
