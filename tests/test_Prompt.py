import pytest
from brownie import (
    PromptContract,
    accounts,
)
from brownie import reverts


@pytest.fixture(scope="module")
def prompt():
    return accounts[0].deploy(PromptContract)


def test_CreatePrompt(prompt):
    pid = prompt.CreatePrompt(
        ["job", "gender"],
        [0, 0],
        "ipfs://aaa",
    )

    assert pid.return_value == 0

    pid = prompt.CreatePrompt(
        ["job2", "gender2"],
        [0, 0],
        "ipfs://bbbb",
    )

    # test if promptId increments
    assert pid.return_value == 1


def test_id2prompt(prompt):
    assert prompt.Id2prompt(0) == (["job", "gender"], [0, 0], "ipfs://aaa")


def test_id2owner(prompt):
    assert prompt.Id2owner(0) == accounts[0]


def test_owner2ids(prompt):
    assert prompt.Owner2ids(accounts[0]) == [0, 1]


def test_UpdatePrompt(prompt):

    # update prompt from a wrong address
    with reverts("Only the owner can update the prompt."):
        prompt.UpdatePrompt(
            0,
            ["job", "gender"],
            [0, 0],
            "ipfs://aaa",
            {"from": accounts[1]},
        )

    with reverts("updating prompt cannot include source id = 0."):
        prompt.UpdatePrompt(
            0,
            ["job3", "gender3"],
            [1, 0],
            "ipfs://ccc",
            {"from": accounts[0]},
        )

    prompt.UpdatePrompt(
        0,
        ["job3", "gender3"],
        [1, 1],
        "ipfs://ccc",
        {"from": accounts[0]},
    )

    assert prompt.Id2prompt(2) == (["job3", "gender3"], [1, 1], "ipfs://ccc")
