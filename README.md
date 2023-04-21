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
- [0xB3e0BeF9e5EeA8c06D84b767a714AD8a6018d133](https://sepolia.etherscan.io/address/0xB3e0BeF9e5EeA8c06D84b767a714AD8a6018d133#code)
