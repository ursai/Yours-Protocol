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
    [0x96f574f280E7EB845fE1AaE02cD7c27EbcfC6e33](https://sepolia.etherscan.io/address/0x96f574f280E7EB845fE1AaE02cD7c27EbcfC6e33#code)
