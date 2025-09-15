# Fomo Faucet
**This contract is a fun take on faucets and a reverse dutch auction game mechanic.** 

The idea is to allow anyone to make a claim of hoodiEth from any wallet. The longer users wait, the larger the claim they can make from the pot. If they wait too long however they increase their chance of being sniped by another player which will restart the claim amount after each new claim. There is a limit of 1 claim per day for each address and a minClaimAmount to prevent ddos style attacks. The game is not designed to ensure complete fairness. I encourage anyone to figure out ways to break the game and claim as much hoodiEth as possible.


## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
