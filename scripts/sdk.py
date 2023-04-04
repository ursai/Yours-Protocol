from brownie import (
    accounts,
    Contract,
)

from brownie.network.transaction import TransactionReceipt
from dataclasses import dataclass


def colord(text):
    RED_ITALIC_BOLD = "\033[91m\033[3m\033[1m"
    END = "\033[0m"
    return f"{RED_ITALIC_BOLD}{text}{END}"


import inspect
from pprint import pformat


def displayArgs(f):
    def wrapper(*args, **kwargs):
        print(colord(f"{accounts.default} is calling {f.__name__}() with arguments:"))
        bound_args = inspect.signature(f).bind(*args, **kwargs)
        bound_args.apply_defaults()

        res = dict(bound_args.arguments)
        del res["self"]
        print(colord(pformat(res, sort_dicts=False)))

        return f(*args, **kwargs)

    return wrapper


@dataclass
class PromptEngineering:
    contract: Contract

    @displayArgs
    def CreatePrompt(
        self,
        params: list[str],
        paramSourceIds: list[int],
        templateType: int,
        template: str,
    ) -> TransactionReceipt:
        return self.contract.CreatePrompt(
            params,
            paramSourceIds,
            templateType,
            template,
        )

    @displayArgs
    def UpdatePrompt(
        self,
        id: int,
        additionalParams: list[str],
        additionalSourceIds: list[int],
        templateType: int,
        template: str,
    ) -> TransactionReceipt:
        return self.contract.UpdatePrompt(
            id,
            additionalParams,
            additionalSourceIds,
            templateType,
            template,
        )

    @displayArgs
    def CreateParameterSource(
        self,
        sourceType: int,
        content: bytes,
    ) -> TransactionReceipt:
        return self.contract.CreateParameterSource(
            sourceType,
            content,
        )

    @displayArgs
    def CreateChatbot(
        self,
        name: str,
        description: str,
        promptId: int,
        promptVersion: int,
        paramSubstantiations: list[tuple[int, int, int, int]],
    ) -> TransactionReceipt:
        return self.contract.CreateChatbot(
            name,
            description,
            promptId,
            promptVersion,
            paramSubstantiations,
        )

    @displayArgs
    def UpdateChatbotPrompt(
        self,
        chatbotId: int,
        newPromptId: int,
        newPromptVersion: int,
        newParamSubstantiations: list[tuple[int, int, int, int]],
    ) -> TransactionReceipt:
        return self.contract.UpdateChatbotPrompt(
            chatbotId,
            newPromptId,
            newPromptVersion,
            newParamSubstantiations,
        )
