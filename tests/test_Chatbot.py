import pytest
from brownie import (
    ChatbotContract,
    accounts,
)


@pytest.fixture(scope="module")
def chatbot():
    return accounts[0].deploy(ChatbotContract)


def test_CreateChatbot(chatbot):
    pid = chatbot.CreateChatbot(
        "GGA chatbot",
        "the best chatbot",
        1,
    )

    assert pid.return_value == 0

    pid = chatbot.CreateChatbot(
        "GGA chatbot v2",
        "the best chatbot",
        0,
    )

    # test if chatbotId increments
    assert pid.return_value == 1


def test_id2chatbot(chatbot):
    assert chatbot.Id2chatbot(0) == ("GGA chatbot", "the best chatbot", 1)


def test_id2owner(chatbot):
    assert chatbot.Id2owner(0) == accounts[0]


def test_owner2ids(chatbot):
    assert chatbot.Owner2ids(accounts[0]) == [0, 1]
