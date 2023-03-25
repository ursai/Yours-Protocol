from _pytest import config
import pytest
from brownie import (
    ChatbotContract,
    PromptContract,
    accounts,
)
from brownie import reverts
from web3 import constants


@pytest.fixture(scope="module")
def prompt():
    _prompt = accounts[0].deploy(PromptContract)
    pid = _prompt.CreatePrompt(
        ["job", "gender"],
        [0, 0],
        "ipfs://aaa",
    )

    assert pid.return_value == 0

    pid = _prompt.CreatePrompt(
        ["job2", "gender2"],
        [0, 0],
        "ipfs://bbbb",
    )

    return _prompt


@pytest.fixture(scope="module")
def chatbot(prompt):
    return accounts[0].deploy(ChatbotContract, prompt)


def test_CreateChatbot(chatbot):
    with reverts("id or version number is invalid."):
        chatbot.CreateChatbot(
            "GGA chatbot",
            "the best chatbot",
            2,
            0,
        )

    with reverts("id or version number is invalid."):
        chatbot.CreateChatbot(
            "GGA chatbot",
            "the best chatbot",
            0,
            9,
        )

    pid = chatbot.CreateChatbot(
        "GGA chatbot",
        "the best chatbot",
        1,
        0,
    )

    assert pid.return_value == 0

    pid = chatbot.CreateChatbot(
        "GGA chatbot v2",
        "the best chatbot",
        0,
        0,
    )

    # test if chatbotId increments
    assert pid.return_value == 1


def test_UpdateChatbotPrompt(chatbot):
    with reverts("Only the owner can update the chatbot."):
        chatbot.UpdateChatbotPrompt(1, 0, 0, {"from": accounts[1]})

    # case: chatbotID is invalid
    with reverts("Only the owner can update the chatbot."):
        chatbot.UpdateChatbotPrompt(99, 0, 0)

    with reverts("id or version number is invalid."):
        chatbot.UpdateChatbotPrompt(1, 9, 0)

    with reverts("id or version number is invalid."):
        chatbot.UpdateChatbotPrompt(1, 9, 0)

    # return promptId, promptVersion
    assert chatbot.Id2chatbot(1)[2:] == (0, 0)
    # alter chatbotId=1 => promptId=1, promptVersion=0
    chatbot.UpdateChatbotPrompt(1, 1, 0)
    assert chatbot.Id2chatbot(1)[2:] == (1, 0)


def test_id2chatbot(chatbot):
    assert chatbot.Id2chatbot(99) == ("", "", 0, 0)
    assert chatbot.Id2chatbot(0) == ("GGA chatbot", "the best chatbot", 1, 0)


def test_id2owner(chatbot):
    assert chatbot.Id2owner(99) == constants.ADDRESS_ZERO
    assert chatbot.Id2owner(0) == accounts[0]


def test_owner2ids(chatbot):
    assert chatbot.Owner2ids(accounts[8]) == ()
    assert chatbot.Owner2ids(accounts[0]) == [0, 1]
