import pytest
from brownie import (
    ParameterSourceContract,
    accounts,
)
from brownie import reverts


@pytest.fixture(scope="module")
def source():
    return accounts[0].deploy(ParameterSourceContract)


def test_CreatePromptParameterSource(source):
    pid = source.CreatePromptParameterSource(
        "On-Chain Text",
        "day dreamer",
    )

    assert pid.return_value == 0

    pid = source.CreatePromptParameterSource(
        "Prompt",
        "2",
    )

    # test if sourceId increments
    assert pid.return_value == 1


def test_id2source(source):
    assert source.Id2source(0) == ("On-Chain Text", "day dreamer")


def test_id2owner(source):
    assert source.Id2owner(0) == accounts[0]


def test_owner2ids(source):
    assert source.Owner2ids(accounts[0]) == [0, 1]
