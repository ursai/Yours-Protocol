from brownie import (
    PromptContract,
    ParameterSourceContract,
    ChatbotContract,
    accounts,
    config,
)


def main():
    accounts.default = myaccount = accounts.add(config["wallets"]["from_key"])
    myaccount.deploy(PromptContract, publish_source=True)
    myaccount.deploy(ParameterSourceContract, publish_source=True)
    myaccount.deploy(ChatbotContract, publish_source=True)
