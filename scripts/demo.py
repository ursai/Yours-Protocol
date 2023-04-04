from brownie import (
    URSPromptEngineering,
    accounts,
    convert,
    config,
    network,
)
from scripts.sdk import PromptEngineering


def pprint(text):
    RED_ITALIC_BOLD = "\033[91m\033[3m\033[1m"
    END = "\033[0m"
    print(f"{RED_ITALIC_BOLD}{text}{END}")


def str_to_hex(val):
    return convert.datatypes.HexString(val.encode(), "bytes")


def uint_to_hex(val):
    return convert.datatypes.HexString(val, "bytes32")


def uints_to_hex(vals):
    result = b""
    for val in vals:
        result += convert.datatypes.HexString(val, "bytes32")
    return convert.datatypes.HexString(result, "bytes")


def main():

    curr_network = network.show_active()
    verify = curr_network != "development"
    accounts.default = myaccount = accounts.add(config["wallets"]["from_key"])

    pprint(f"{accounts.default} deploys {URSPromptEngineering._name} to {curr_network}")
    urs_pre = myaccount.deploy(URSPromptEngineering, publish_source=verify)

    pprint("Demo URSPromptEngineering Smart Contract Functionality...")
    urs_pe = PromptEngineering(urs_pre)
    urs_pe.CreatePrompt([], [], 1, "ipfs://prompt_addr")
    urs_pe.CreatePrompt(["profession"], [0], 0, "Write a job description for {{0}}")
    urs_pe.CreateParameterSource(1, str_to_hex("male"))
    urs_pe.CreateParameterSource(2, str_to_hex("ipfs://source_addr"))
    urs_pe.CreateParameterSource(3, uints_to_hex((1, 0)))
    urs_pe.UpdatePrompt(0, ["gender"], [1], 1, "ipfs://prompt_addr")
    urs_pe.CreateChatbot("bot", "testing", 0, 0, [])

    pprint("Demo Create Chatbot From Nested Prompts...")

    urs_pe.CreatePrompt(
        ["age", "gender", "job-description"], [0, 1, 3], 1, "ipfs://prompt_addr"
    )

    tx = urs_pe.CreateParameterSource(1, str_to_hex("25"))
    # tx.return_value is not available in free ETH APIs
    age_source_id = tx.events["ParameterSourceCreated"]["paramSourceId"]

    tx = urs_pe.CreateParameterSource(1, str_to_hex("farmer"))
    profession_source_id = tx.events["ParameterSourceCreated"]["paramSourceId"]
    urs_pe.CreateChatbot(
        "bot",
        "testing",
        2,
        0,
        [(2, 0, 0, age_source_id), (1, 0, 0, profession_source_id)],
    )

    if verify:
        pprint("we can also verify the result on etherscan.io")
        pprint(
            f"https://{curr_network}.etherscan.io/address/{urs_pe.contract.address}#writeContract"
        )
