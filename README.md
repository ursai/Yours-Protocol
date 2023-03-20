# eth-template
eth-template

## test
- python3 <= 3.10.9
- [brownie](https://eth-brownie.readthedocs.io/en/stable/index.html)
  ```shell
  pip install brownie
  brownie init -f
  ```

- [ganache](https://github.com/trufflesuite/ganache)
  ```shell
  npm install ganache --global
  ```

- run test
  ```shell
  brownie test
  ```

## deploy
- set variables in _.env_ file

- use brownie to deploy and verify source code on etherscan
  ```shell
  brownie deploy [--network [sepolia]]
  ```

## deployed contracts on sepolia
- Prompt: [`0x39B6FAcF814148ba12FE7eE3afe98db1D39588a7`](https://sepolia.etherscan.io/address/0x39B6FAcF814148ba12FE7eE3afe98db1D39588a7)
- ParameterSource: [`0xf18C27e72cB56AE8A9112B4F4a24684f56E637EA`](https://sepolia.etherscan.io/address/0xf18C27e72cB56AE8A9112B4F4a24684f56E637EA)
- Chatbot: [`0x1A4D674c1233d733d2014010Ce2AC6647bA3aE87`](https://sepolia.etherscan.io/address/0x1A4D674c1233d733d2014010Ce2AC6647bA3aE87)
