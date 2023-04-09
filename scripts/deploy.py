from brownie import (
    URSPromptEngineering,
    accounts,
    config,
    network,
)


def main():
    verify = network.show_active() != "development"
    accounts.default = myaccount = accounts.add(config["wallets"]["from_key"])
    myaccount.deploy(URSPromptEngineering, publish_source=verify)
