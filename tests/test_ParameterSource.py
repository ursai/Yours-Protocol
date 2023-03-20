import pytest
from brownie import (
    ParameterSourceContract,
    accounts,
)
from brownie import reverts
from web3 import constants


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
    assert source.Id2source(99) == ("", "")
    assert source.Id2source(0) == ("On-Chain Text", "day dreamer")


def test_id2owner(source):
    assert source.Id2owner(99) == constants.ADDRESS_ZERO
    assert source.Id2owner(0) == accounts[0]


def test_owner2ids(source):
    assert source.Owner2ids(accounts[9]) == ()
    assert source.Owner2ids(accounts[0]) == [0, 1]
