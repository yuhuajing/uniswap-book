---
title: "开发环境"
weight: 4
# bookFlatSection: false
# bookToc: true
# bookHidden: false
# bookCollapseSection: false
# bookComments: false
# bookSearchExclude: false
---

# 开发环境

本书中，我们会学习：
1. 一套部署在Solana链上的智能合约
2. 链下调用Solana合约的SDK

## 本地开发环境

我们将要搭建智能合约并且在Solana上运行它们，这意味着我们需要一个节点。在本地测试和运行合约也需要一个节点。曾经这使得智能合约开发十分麻烦，因为在一个真实节点上运行大量的测试会十分缓慢。不过现在已经有了很多快速简洁的解决方案。例如 [solana-test-validator]() 直接构建本地链，不过这些工具的问题在于我们需要用 JavaScript 来写测试以及与区块链的交互。

### MetaMask

[MetaMask](https://metamask.io/) 是一个浏览器中的钱包。它是一个浏览器插件，可以安全地创建和存储私钥。Metamask 也是最常用的以太坊钱包应用，我们将使用它来与我们的本地运行的节点进行交互。

## [准备开发环境](https://solana.com/zh/docs/intro/installation#solana-cli-basics)

安装 Rust：
```shell
# install rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
```
安装 Solana cli
```shell
# install solana
sh -c "$(curl -sSfL https://release.anza.xyz/stable/install)"
```
查询目前的Solana版本 `https://github.com/anza-xyz/agave/releases`

更新 Solana
```shell
agave-install update
```

安装 Anchor
```shell
cargo install --git https://github.com/coral-xyz/anchor avm --force

avm install latest
avm use latest
```

## [Solana基础语句](https://solana.com/zh/docs/intro/installation#solana-cli-basics)

获取本地Solana配置
```shell
solana config get
```
输出本地的Solana节点配置信息,包含RPC和WS节点端口
```text
Config File: /root/.config/solana/cli/config.yml
RPC URL: http://127.0.0.1:8899
WebSocket URL: ws://127.0.0.1:8900/ (computed)
Keypair Path: /root/.config/solana/id.json
Commitment: confirmed
```

设置本地的Solana的配置
```shell
solana config set --url mainnet-beta
solana config set --url devnet
solana config set --url localhost
solana config set --url testnet
```
创建钱包地址
```shell
solana-keygen new 
```
在已经有钱包地址时，可以强制创建新的地址进行替换
```shell
solana-keygen new --force
```
查看 Solana 地址
```shell
solana address
```
领取测试网空投
```shell
solana airdrop 2
```
启动本地的Solana测试网
```shell
solana-test-validator
```

## Anchor基础语句
Anchor是构建Solana合约的框架

初始化项目
```shell
anchor init <project-name>
```
进入文件目录，构建/测试/部署文件
```shell
anchor build

anchor test 

anchor deploy
```