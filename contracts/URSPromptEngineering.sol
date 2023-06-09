// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Context.sol";

contract URSPromptEngineering is Context {

    // Struct definitions
    struct Prompt {
        // TODO: maybe add name/descriptin to prompt as well; alternatively, maybe we should remove name/description from chatbot struct
        string[] params;
        uint32[] paramSourceIds;
        // TODO: add a mapping from an index in this.paramSourceIds to a ParameterRef that points to a referenced prompt's unsubstantiated parameter
        //       this will allow the same parameter to be used to fill out multiple templates
        uint8 templateType;
        string template;
    }

    struct ParameterRef {
        uint32 promptId;
        uint32 paramIndex;
    }

    struct ParameterSource {
        uint8 sourceType;
        bytes content;
    }

    struct Chatbot {
        string name;
        string description;
        uint32 promptId;
        uint32 promptVersion;
        ParameterSubstantiation[] paramSubstantiations;
    }

    struct ParameterSubstantiation {
        uint32 promptId;
        uint32 paramIndex;
        uint32 sourceId;
    }

    // Event definitions
    event PromptCreated(address indexed owner, uint32 indexed promptId);
    event PromptUpdated(uint32 indexed promptId, uint256 indexed latestVersion);
    event ParameterSourceCreated(address indexed owner, uint32 indexed paramSourceId);
    event ChatbotCreated(address indexed owner, uint32 indexed chatbotId);
    event ChatbotUpdated(uint32 indexed chatbotId, uint32 newPromptId, uint32 newPromptVersion);

    // Internal data structure definitions
    uint32 private nextPromptId;
    mapping(uint32 => Prompt[]) private idPromptMap;
    mapping(uint32 => address) private idPromptOwnerMap;
    mapping(address => uint32[]) private ownerPromptIdsMap;
    mapping(uint32 => ParameterRef[]) private idUnsubstantiatedParamsMap;

    uint32 private nextSourceId = 1; // 0 is the ID reserved for unspecified sources
    mapping(uint32 => ParameterSource) private idSourceMap;
    mapping(uint32 => address) private idSourceOwnerMap;
    mapping(address => uint32[]) private ownerSourceIdsMap;

    uint32 private nextChatbotId;
    mapping(uint32 => Chatbot) private idChatbotMap;
    mapping(uint32 => address) private idChatbotOwnerMap;
    mapping(address => uint32[]) private ownerChatbotIdsMap;

    // Getter methods for Prompt, ParameterSource, and Chatbot
    function GetPrompt(
        uint32 id,
        uint32 version
    ) external view returns (Prompt memory) {
        return idPromptMap[id][version];
    }

    function GetPromptLatestVersionNumber(uint32 id) external view returns (uint256) {
        return idPromptMap[id].length - 1;
    }

    function GetPromptOwner(uint32 id) external view returns (address) {
        return idPromptOwnerMap[id];
    }

    function GetPromptIdsByOwner(address owner) external view returns (uint32[] memory) {
        return ownerPromptIdsMap[owner];
    }

    function GetPromptUnsubstantiatedParams(uint32 id) external view returns (ParameterRef[] memory) {
        return idUnsubstantiatedParamsMap[id];
    }

    function GetParameterSource(uint32 id) external view returns (ParameterSource memory) {
        return idSourceMap[id];
    }

    function GetParameterSourceOwner(uint32 id) external view returns (address) {
        return idSourceOwnerMap[id];
    }

    function GetParameterSourceIdsByOwner(address owner) external view returns (uint32[] memory) {
        return ownerSourceIdsMap[owner];
    }

    function GetChatbot(uint32 id) external view returns (Chatbot memory) {
        return idChatbotMap[id];
    }

    function GetChatbotOwner(uint32 id) external view returns (address) {
        return idChatbotOwnerMap[id];
    }

    function GetChatbotIdsByOwner(address owner) external view returns (uint32[] memory) {
        return ownerChatbotIdsMap[owner];
    }

    // Prompt methods
    function CreatePrompt(
        string[] memory params,
        uint32[] calldata paramSourceIds,
        uint8 templateType,
        string calldata template
    ) external returns (uint32) {
        // TODO: add prompt source loop detection
        // TODO: convert transaction revert strings to bronwnie dev comments to save gas
        require(IsPromptSourceValid(params, paramSourceIds, false), "Invalid prompt parameter sources");

        uint32 promptId = nextPromptId;
        ++nextPromptId;

        Prompt storage prompt = idPromptMap[promptId].push();
        prompt.params = params;
        prompt.paramSourceIds = paramSourceIds;
        prompt.templateType = templateType;
        prompt.template = template;
        idPromptOwnerMap[promptId] = _msgSender();
        ownerPromptIdsMap[_msgSender()].push(promptId);

        PopulateUnsubstantiatedParams(promptId);

        emit PromptCreated(_msgSender(), promptId);
        return promptId;
    }

    function UpdatePrompt(
        uint32 id,
        // TODO: also allow updates to existing source IDs
        string[] memory additionalParams,
        uint32[] calldata additionalSourceIds,
        uint8 templateType,
        string calldata template
    ) external returns (uint256) {
        require(idPromptMap[id].length > 0, "Prompt does not exist");
        require(idPromptOwnerMap[id] == _msgSender(), "Only the owner can update the prompt");
        require(IsPromptSourceValid(additionalParams, additionalSourceIds, true), "Invalid additioal prompt parameter sources");

        Prompt storage latestPrompt = idPromptMap[id].push();
        uint256 latestVersion = idPromptMap[id].length - 1;
        Prompt storage previousPrompt = idPromptMap[id][latestVersion - 1];

        latestPrompt.params = previousPrompt.params;
        latestPrompt.paramSourceIds = previousPrompt.paramSourceIds;
        for (uint32 i = 0; i < additionalParams.length; ++i) {
            latestPrompt.params.push(additionalParams[i]);
            latestPrompt.paramSourceIds.push(additionalSourceIds[i]);
        }
        latestPrompt.templateType = templateType;
        latestPrompt.template = template;

        emit PromptUpdated(id, latestVersion);
        return latestVersion;
    }

    function IsPromptSourceValid(
        string[] memory params,
        uint32[] calldata paramSourceIds,
        bool requireSubstantiation
    ) internal view returns (bool) {
        if (params.length != paramSourceIds.length) {
            return false;
        }
        for (uint32 i = 0; i < params.length; ++i) {
            if (paramSourceIds[i] == 0) {
                if (requireSubstantiation) {
                    return false;
                }
            } else {
                ParameterSource storage source = idSourceMap[paramSourceIds[i]];
                if (source.sourceType == 0) {
                    return false;
                }
                if (requireSubstantiation && !IsParameterSourceSubstantiated(source)) {
                    return false;
                }
            }
        }
        return true;
    }

    function PopulateUnsubstantiatedParams(uint32 promptId) internal {
        Prompt storage prompt = idPromptMap[promptId][0];
        ParameterRef[] storage unsubstantiatedParams = idUnsubstantiatedParamsMap[promptId];
        for (uint32 i = 0; i < prompt.params.length; ++i) {
            uint32 sourceId = prompt.paramSourceIds[i];
            if (sourceId == 0) {
                unsubstantiatedParams.push(ParameterRef(promptId, i));
            } else {
                ParameterSource memory source = idSourceMap[sourceId];
                // Source type 3 means the source is another prompt
                // TODO: we should probably add a constant store instead of hard-coding 3 here
                if (source.sourceType == 3)
                {
                    uint32 sourcePromptId = GetPromptIdFromParameterSource(source);
                    ParameterRef[] storage sourceUnsubstantiatedParams = idUnsubstantiatedParamsMap[sourcePromptId];
                    for (uint32 j = 0; j < sourceUnsubstantiatedParams.length; ++j) {
                        unsubstantiatedParams.push(sourceUnsubstantiatedParams[j]);
                    }
                }
            }
        }
    }

    function CreateStringParameterSource(string calldata str) external returns (uint32) {
        return CreateParameterSource(1, bytes(str));
    }

    function CreateIPFSParameterSource(string calldata ipfsAddr) external returns (uint32) {
        return CreateParameterSource(2, bytes(ipfsAddr));
    }

    function CreatePromptParameterSource(
        uint32 promptId,
        uint32 promptVersion
    ) external returns (uint32) {
        bytes memory content;
        content = abi.encode(promptId, promptVersion);
        return CreateParameterSource(3, content);
    }

    // ParameterSource methods
    function CreateParameterSource(
        uint8 sourceType,
        bytes memory content
    ) internal returns (uint32) {
        require(sourceType > 0, "SourceType must be positive");

        uint32 sourceId = nextSourceId;
        ++nextSourceId;

        idSourceMap[sourceId] = ParameterSource(sourceType, content);
        idSourceOwnerMap[sourceId] = _msgSender();
        ownerSourceIdsMap[_msgSender()].push(sourceId);

        if (sourceType == 3) {
            (uint32 promptId, uint32 promptVersion) = GetPromptFromParameterSource(idSourceMap[sourceId]);
            require(promptVersion < idPromptMap[promptId].length, "Source prompt does not exist");
        }

        emit ParameterSourceCreated(_msgSender(), sourceId);
        return sourceId;
    }

    function IsParameterSourceSubstantiated(ParameterSource memory source) internal view returns (bool) {
        if (source.sourceType != 3) {
            return true;
        }
        uint32 promptId = GetPromptIdFromParameterSource(source);
        return idUnsubstantiatedParamsMap[promptId].length == 0;
    }

    function GetPromptFromParameterSource(ParameterSource memory source) internal pure returns (uint32, uint32) {
        require(source.sourceType == 3, "Only applicable to parameter with type 3");

        (uint32 promptId, uint32 promptVersion) = abi.decode(source.content, (uint32, uint32));

        return (promptId, promptVersion);
    }

    function GetPromptIdFromParameterSource(ParameterSource memory source) internal pure returns (uint32) {
        require(source.sourceType == 3, "Only applicable to parameter with type 3");

        (uint32 promptId, ) = abi.decode(source.content, (uint32, uint32));

        return promptId;
    }

    function GetPromptVersionFromParameterSource(ParameterSource memory source) internal pure returns (uint32) {
        require(source.sourceType == 3, "Only applicable to parameter with type 3");

        (, uint32 promptVersion) = abi.decode(source.content, (uint32, uint32));
        return promptVersion;
    }

    // TODO: implement source type 4: On-Chain Smart Contract Output

    // Chatbot methods
    function CreateChatbot(
        string calldata name,
        string calldata description,
        uint32 promptId,
        uint32 promptVersion,
        ParameterSubstantiation[] memory paramSubstantiations
    ) external returns (uint32) {
        require(bytes(name).length > 0, "Chatbot name must be non-empty");
        require(idPromptMap[promptId].length > 0, "Chatbot prompt does not exist");
        require(promptVersion < idPromptMap[promptId].length, "Chatbot prompt version does not exist");
        require(IsFullySubstantiated(idUnsubstantiatedParamsMap[promptId], paramSubstantiations), "Chatbot must have a fully substantiated prompt");

        uint32 chatbotId = nextChatbotId;
        ++nextChatbotId;

        Chatbot storage chatbot = idChatbotMap[chatbotId];
        chatbot.name = name;
        chatbot.description = description;
        chatbot.promptId = promptId;
        chatbot.promptVersion = promptVersion;
        for (uint32 i = 0; i < paramSubstantiations.length; ++i) {
            chatbot.paramSubstantiations.push(paramSubstantiations[i]);
        }

        idChatbotOwnerMap[chatbotId] = _msgSender();
        ownerChatbotIdsMap[_msgSender()].push(chatbotId);

        emit ChatbotCreated(_msgSender(), chatbotId);
        return chatbotId;
    }

    function UpdateChatbotPrompt(
        uint32 chatbotId,
        uint32 newPromptId,
        uint32 newPromptVersion,
        ParameterSubstantiation[] memory newParamSubstantiations
    ) external {
        require(bytes(idChatbotMap[chatbotId].name).length > 0, "Chatbot does not exist");
        require(idChatbotOwnerMap[chatbotId] == _msgSender(), "Only the owner can update the chatbot");
        require(idPromptMap[newPromptId].length > 0, "Chatbot new prompt does not exist");
        require(newPromptVersion < idPromptMap[newPromptId].length, "Chatbot new prompt version does not exist");
        require(IsFullySubstantiated(idUnsubstantiatedParamsMap[newPromptId], newParamSubstantiations), "Chatbot must have a fully substantiated prompt");

        Chatbot storage chatbot = idChatbotMap[chatbotId];
        chatbot.promptId = newPromptId;
        chatbot.promptVersion = newPromptVersion;

        if (chatbot.paramSubstantiations.length > newParamSubstantiations.length) {
            for (uint32 i = 0; i < newParamSubstantiations.length; ++i) {
                chatbot.paramSubstantiations[i] = newParamSubstantiations[i];
            }
            for (uint256 i = newParamSubstantiations.length; i < chatbot.paramSubstantiations.length; ++i) {
                chatbot.paramSubstantiations.pop();
            }
        } else {
            for (uint32 i = 0; i < chatbot.paramSubstantiations.length; ++i) {
                chatbot.paramSubstantiations[i] = newParamSubstantiations[i];
            }
            for (uint256 i = chatbot.paramSubstantiations.length; i < newParamSubstantiations.length; ++i) {
                chatbot.paramSubstantiations.push(newParamSubstantiations[i]);
            }
        }

        emit ChatbotUpdated(chatbotId, newPromptId, newPromptVersion);
    }

    function IsFullySubstantiated(
        ParameterRef[] memory paramRefs,
        ParameterSubstantiation[] memory substantiations
    ) internal pure returns (bool) {
        if (paramRefs.length != substantiations.length) {
            return false;
        }
        for (uint32 i = 0; i < paramRefs.length; ++i) {
            bool isParamSubstantiated = false;
            for (uint32 j = 0; j < paramRefs.length; ++j) {
                if (IsParamSubstantiated(paramRefs[i], substantiations[j])) {
                    isParamSubstantiated = true;
                    break;
                }
            }
            if (!isParamSubstantiated) {
                return false;
            }
        }
        return true;
    }

    function IsParamSubstantiated(
        ParameterRef memory paramRef,
        ParameterSubstantiation memory substantiation
    ) internal pure returns (bool) {
        if (paramRef.promptId != substantiation.promptId) {
            return false;
        }
        if (paramRef.paramIndex != substantiation.paramIndex) {
            return false;
        }
        if (substantiation.sourceId == 0 || substantiation.sourceId == 3) {
            return false;
        }
        return true;
    }
}
