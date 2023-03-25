from brownie import (
    PromptContract,
    ParameterSourceContract,
    ChatbotContract,
    accounts,
    config,
    network,
)


def main():
    verify = network.show_active() != "development"
    accounts.default = myaccount = accounts.add(config["wallets"]["from_key"])
    prompt = myaccount.deploy(PromptContract, publish_source=verify)
    myaccount.deploy(ParameterSourceContract, publish_source=verify)
    myaccount.deploy(ChatbotContract, prompt, publish_source=verify)
