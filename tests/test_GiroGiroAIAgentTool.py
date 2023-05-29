import pytest
from brownie import (
    GiroGiroAIAgentTool,
    accounts,
    reverts,
    convert,
)
from web3 import constants


def str_to_hex(val):
    return convert.datatypes.HexString(val.encode(), "bytes")


def uint_to_hex(val):
    return convert.datatypes.HexString(val, "bytes32")


def uints_to_hex(vals):
    result = b""
    for val in vals:
        result += convert.datatypes.HexString(val, "bytes32")
    return convert.datatypes.HexString(result, "bytes")


@pytest.fixture(scope="module")
def urs_pe():
    return accounts[0].deploy(GiroGiroAIAgentTool)


def test_CreatePrompt(urs_pe):
    tx = urs_pe.CreatePrompt([], [], 1, "ipfs://prompt_addr")
    assert tx.return_value == 0
    assert urs_pe.GetPrompt(0, 0) == ([], [], 1, "ipfs://prompt_addr")
    assert urs_pe.GetPromptLatestVersionNumber(0) == 0
    assert urs_pe.GetPromptOwner(0) == accounts[0]
    assert urs_pe.GetPromptIdsByOwner(accounts[0]) == [0]

    tx = urs_pe.CreatePrompt(
        ["profession"], [0], 0, "Write a job description for {{0}}"
    )
    assert tx.return_value == 1
    assert urs_pe.GetPrompt(1, 0) == (
        ["profession"],
        [0],
        0,
        "Write a job description for {{0}}",
    )
    assert urs_pe.GetPromptLatestVersionNumber(1) == 0
    assert urs_pe.GetPromptOwner(1) == accounts[0]
    assert urs_pe.GetPromptIdsByOwner(accounts[0]) == [0, 1]
    assert urs_pe.GetPromptUnsubstantiatedParams(1) == [(1, 0)]

    with reverts("Invalid prompt parameter sources"):
        urs_pe.CreatePrompt(["profession", "gender"], [0, 1], 1, "ipfs://prompt_addr")
    with reverts("Invalid prompt parameter sources"):
        urs_pe.CreatePrompt(["profession", "gender"], [0], 1, "ipfs://prompt_addr")


def test_CreateParameterSource(urs_pe):
    tx = urs_pe.CreateStringParameterSource("male")
    assert tx.return_value == 1
    assert urs_pe.GetParameterSource(1) == (1, str_to_hex("male"))
    assert urs_pe.GetParameterSourceOwner(1) == accounts[0]
    assert urs_pe.GetParameterSourceIdsByOwner(accounts[0]) == [1]

    tx = urs_pe.CreateIPFSParameterSource("ipfs://source_addr")
    assert tx.return_value == 2
    assert urs_pe.GetParameterSource(2) == (2, str_to_hex("ipfs://source_addr"))
    assert urs_pe.GetParameterSourceOwner(2) == accounts[0]
    assert urs_pe.GetParameterSourceIdsByOwner(accounts[0]) == [1, 2]

    tx = urs_pe.CreatePromptParameterSource(1, 0)
    assert tx.return_value == 3
    assert urs_pe.GetParameterSource(3) == (3, uints_to_hex((1, 0)))
    assert urs_pe.GetParameterSourceOwner(3) == accounts[0]
    assert urs_pe.GetParameterSourceIdsByOwner(accounts[0]) == [1, 2, 3]

    with reverts("Source prompt does not exist"):
        urs_pe.CreatePromptParameterSource(2, 0)
    with reverts("Source prompt does not exist"):
        urs_pe.CreatePromptParameterSource(0, 1)


def test_UpdatePrompt(urs_pe):
    tx = urs_pe.UpdatePrompt(0, ["gender"], [1], 1, "ipfs://prompt_addr")
    assert tx.return_value == 1
    assert urs_pe.GetPrompt(0, 0) == ([], [], 1, "ipfs://prompt_addr")
    assert urs_pe.GetPrompt(0, 1) == (["gender"], [1], 1, "ipfs://prompt_addr")
    assert urs_pe.GetPromptLatestVersionNumber(0) == 1
    assert urs_pe.GetPromptUnsubstantiatedParams(0) == []

    with reverts("Invalid additioal prompt parameter sources"):
        urs_pe.UpdatePrompt(
            0, ["nationality", "birthday"], [2], 1, "ipfs://prompt_addr"
        )
    with reverts("Invalid additioal prompt parameter sources"):
        urs_pe.UpdatePrompt(0, ["nationality"], [0], 1, "ipfs://prompt_addr")
    with reverts("Invalid additioal prompt parameter sources"):
        urs_pe.UpdatePrompt(0, ["job-description"], [3], 1, "ipfs://prompt_addr")
    with reverts("Prompt does not exist"):
        urs_pe.UpdatePrompt(2, [], [], 1, "ipfs://prompt_addr")


def test_CreateChatbot(urs_pe):
    tx = urs_pe.CreateChatbot("bot", "testing", 0, 0, [])
    assert tx.return_value == 0
    assert urs_pe.GetChatbot(0) == ("bot", "testing", 0, 0, [])
    assert urs_pe.GetChatbotOwner(0) == accounts[0]
    assert urs_pe.GetChatbotIdsByOwner(accounts[0]) == [0]

    with reverts("Chatbot name must be non-empty"):
        urs_pe.CreateChatbot("", "chatbot-with-empty-name", 0, 0, [])
    with reverts("Chatbot prompt does not exist"):
        urs_pe.CreateChatbot("bot", "", 3, 0, [])
    with reverts("Chatbot prompt version does not exist"):
        urs_pe.CreateChatbot("bot", "", 1, 1, [])
    with reverts("Chatbot must have a fully substantiated prompt"):
        urs_pe.CreateChatbot("bot", "", 1, 0, [])
    with reverts("Chatbot must have a fully substantiated prompt"):
        urs_pe.CreateChatbot("bot", "", 1, 0, [(0, 0, 1)])


def test_CreateChatbotFromNestedPrompt(urs_pe):
    tx = urs_pe.CreatePrompt(
        ["age", "gender", "job-description"], [0, 1, 3], 1, "ipfs://prompt_addr"
    )
    assert tx.return_value == 2
    assert urs_pe.GetPromptLatestVersionNumber(2) == 0
    assert urs_pe.GetPromptOwner(2) == accounts[0]
    assert urs_pe.GetPromptIdsByOwner(accounts[0]) == (0, 1, 2)
    assert urs_pe.GetPrompt(2, 0) == (
        ["age", "gender", "job-description"],
        [0, 1, 3],
        1,
        "ipfs://prompt_addr",
    )
    assert urs_pe.GetPromptUnsubstantiatedParams(2) == [(2, 0), (1, 0)]

    age_source_id = urs_pe.CreateStringParameterSource("25").return_value
    profession_source_id = urs_pe.CreateStringParameterSource("farmer").return_value
    tx = urs_pe.CreateChatbot(
        "bot",
        "testing",
        2,
        0,
        [(2, 0, age_source_id), (1, 0, profession_source_id)],
    )
    assert tx.return_value == 1
    assert urs_pe.GetChatbot(1) == (
        "bot",
        "testing",
        2,
        0,
        [(2, 0, age_source_id), (1, 0, profession_source_id)],
    )
    assert urs_pe.GetChatbotOwner(1) == accounts[0]
    assert urs_pe.GetChatbotIdsByOwner(accounts[0]) == [0, 1]


def test_UpdateChatbotPrompt(urs_pe):

    # old length(=1) < new length(=2)
    age_source_id = urs_pe.CreateStringParameterSource("25").return_value
    profession_source_id = urs_pe.CreateStringParameterSource("farmer").return_value
    urs_pe.UpdateChatbotPrompt(
        0, 2, 0, [(2, 0, age_source_id), (1, 0, profession_source_id)]
    )
    assert urs_pe.GetChatbot(0) == (
        "bot",
        "testing",
        2,
        0,
        [(2, 0, age_source_id), (1, 0, profession_source_id)],
    )

    # old length(=2) > new length(=1)
    urs_pe.UpdateChatbotPrompt(0, 1, 0, [(1, 0, 1)])
    assert urs_pe.GetChatbot(0) == (
        "bot",
        "testing",
        1,
        0,
        [(1, 0, 1)],
    )
    # old length(=1) == new length(=1)
    urs_pe.UpdateChatbotPrompt(0, 1, 0, [(1, 0, 2)])
    assert urs_pe.GetChatbot(0) == (
        "bot",
        "testing",
        1,
        0,
        [(1, 0, 2)],
    )

    with reverts("Chatbot does not exist"):
        urs_pe.UpdateChatbotPrompt(2, 1, 0, [(1, 0, 2)])
    with reverts("Chatbot new prompt does not exist"):
        urs_pe.UpdateChatbotPrompt(0, 3, 0, [])
    with reverts("Chatbot new prompt version does not exist"):
        urs_pe.UpdateChatbotPrompt(0, 0, 2, [])
    with reverts("Chatbot must have a fully substantiated prompt"):
        urs_pe.UpdateChatbotPrompt(0, 1, 0, [])
