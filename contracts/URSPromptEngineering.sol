// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Context.sol";

contract URSPromptEngineering is Context {

    // Struct definitions
    struct Prompt {
        // TODO: maybe add name/descriptin to prompt as well; alternatively, maybe we should remove name/description from chatbot struct
        string[] params;
        uint256[] paramSourceIds;
        ParameterRef[] unsubstantiatedParams; // auto-generated
        // TODO: add a mapping from an index in this.paramSourceIds to a ParameterRef that points to a referenced prompt's unsubstantiated parameter
        //       this will allow the same parameter to be used to fill out multiple templates
        uint256 templateType;
        string template;
    }

    struct ParameterRef {
        uint256 promptId;
        uint256 promptVersion;
        uint256 paramIndex;
    }

    struct ParameterSource {
        uint256 sourceType;
        bytes content;
    }

    struct Chatbot {
        string name;
        string description;
        uint256 promptId;
        uint256 promptVersion;
        ParameterSubstantiation[] paramSubstantiations;
    }

    struct ParameterSubstantiation {
        uint256 promptId;
        uint256 promptVersion;
        uint256 paramIndex;
        uint256 sourceId;
    }

    // Event definitions
    event PromptCreated(address indexed owner, uint256 indexed promptId);
    event PromptUpdated(uint256 indexed promptId, uint256 indexed latestVersion);
    event ParameterSourceCreated(address indexed owner, uint256 indexed paramSourceId);
    event ChatbotCreated(address indexed owner, uint256 indexed chatbotId);
    event ChatbotUpdated(uint256 indexed chatbotId, uint256 newPromptId, uint256 newPromptVersion);

    // Internal data structure definitions
    uint256 private nextPromptId;
    mapping(uint256 => Prompt[]) private idPromptMap;
    mapping(uint256 => address) private idPromptOwnerMap;
    mapping(address => uint256[]) private ownerPromptIdsMap;

    uint256 private nextSourceId = 1; // 0 is the ID reserved for unspecified sources
    mapping(uint256 => ParameterSource) private idSourceMap;
    mapping(uint256 => address) private idSourceOwnerMap;
    mapping(address => uint256[]) private ownerSourceIdsMap;

    uint256 private nextChatbotId;
    mapping(uint256 => Chatbot) private idChatbotMap;
    mapping(uint256 => address) private idChatbotOwnerMap;
    mapping(address => uint256[]) private ownerChatbotIdsMap;

    // Getter methods for Prompt, ParameterSource, and Chatbot
    function GetPrompt(
        uint256 id,
        uint256 version
    ) external view returns (Prompt memory) {
        return idPromptMap[id][version];
    }

    function GetPromptLatestVersionNumber(uint256 id) external view returns (uint256) {
        return idPromptMap[id].length - 1;
    }

    function GetPromptOwner(uint256 id) external view returns (address) {
        return idPromptOwnerMap[id];
    }

    function GetPromptIdsByOwner(address owner) external view returns (uint256[] memory) {
        return ownerPromptIdsMap[owner];
    }

    function GetParameterSource(uint256 id) external view returns (ParameterSource memory) {
        return idSourceMap[id];
    }

    function GetParameterSourceOwner(uint256 id) external view returns (address) {
        return idSourceOwnerMap[id];
    }

    function GetParameterSourceIdsByOwner(address owner) external view returns (uint256[] memory) {
        return ownerSourceIdsMap[owner];
    }

    function GetChatbot(uint256 id) external view returns (Chatbot memory) {
        return idChatbotMap[id];
    }

    function GetChatbotOwner(uint256 id) external view returns (address) {
        return idChatbotOwnerMap[id];
    }

    function GetChatbotIdsByOwner(address owner) external view returns (uint256[] memory) {
        return ownerChatbotIdsMap[owner];
    }

    // Prompt methods
    function CreatePrompt(
        string[] memory params,
        uint256[] calldata paramSourceIds,
        uint256 templateType,
        string calldata template
    ) external returns (uint256) {
        // TODO: add prompt source loop detection
        // TODO: convert transaction revert strings to bronwnie dev comments to save gas
        require(IsPromptSourceValid(params, paramSourceIds, false), "Invalid prompt parameter sources");

        uint256 promptId = nextPromptId;
        ++nextPromptId;

        Prompt storage prompt = idPromptMap[promptId].push();
        prompt.params = params;
        prompt.paramSourceIds = paramSourceIds;
        prompt.templateType = templateType;
        prompt.template = template;
        idPromptOwnerMap[promptId] = _msgSender();
        ownerPromptIdsMap[_msgSender()].push(promptId);

        GetUnsubstantiatedParams(promptId, 0);

        emit PromptCreated(_msgSender(), promptId);
        return promptId;
    }

    function UpdatePrompt(
        uint256 id,
        // TODO: also allow updates to existing source IDs
        string[] memory additionalParams,
        uint256[] calldata additionalSourceIds,
        uint256 templateType,
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
        for (uint256 i = 0; i < additionalParams.length; ++i) {
            latestPrompt.params.push(additionalParams[i]);
            latestPrompt.paramSourceIds.push(additionalSourceIds[i]);
        }
        latestPrompt.templateType = templateType;
        latestPrompt.template = template;
        // IsPromptSourceValid already ensures that no new unsubstantiated parameter is generated
        // TODO: since the list of unsubstantiated parameters is the same for different versions, we should only store one copy per prompt ID
        latestPrompt.unsubstantiatedParams = previousPrompt.unsubstantiatedParams;

        emit PromptUpdated(id, latestVersion);

        return latestVersion;
    }

    function IsPromptSourceValid(
        string[] memory params,
        uint256[] calldata paramSourceIds,
        bool requireSubstantiation
    ) internal view returns (bool) {
        if (params.length != paramSourceIds.length) {
            return false;
        }
        for (uint256 i = 0; i < params.length; ++i) {
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

    function GetUnsubstantiatedParams(
        uint256 promptId,
        uint256 promptVersion
    ) internal {
        Prompt storage prompt = idPromptMap[promptId][promptVersion];
        for (uint256 i = 0; i < prompt.params.length; ++i) {
            uint256 sourceId = prompt.paramSourceIds[i];
            if (sourceId == 0) {
                prompt.unsubstantiatedParams.push(ParameterRef(promptId, promptVersion, i));
            } else {
                ParameterSource memory source = idSourceMap[sourceId];
                // Source type 3 means the source is another prompt
                // TODO: we should probably add a constant store instead of hard-coding 3 here
                if (source.sourceType == 3)
                {
                    (uint256 sourcePromptId, uint256 sourcePromptVersion) = GetPromptFromParameterSource(source);
                    Prompt storage sourcePrompt = idPromptMap[sourcePromptId][sourcePromptVersion];
                    for (uint256 j = 0; j < sourcePrompt.unsubstantiatedParams.length; ++j) {
                        prompt.unsubstantiatedParams.push(sourcePrompt.unsubstantiatedParams[j]);
                    }
                }
            }
        }
    }

    // ParameterSource methods
    function CreateParameterSource(
        uint256 sourceType,
        bytes calldata content
    ) external returns (uint256) {
        require(sourceType > 0, "SourceType must be positive");

        uint256 sourceId = nextSourceId;
        ++nextSourceId;

        idSourceMap[sourceId] = ParameterSource(sourceType, content);
        idSourceOwnerMap[sourceId] = _msgSender();
        ownerSourceIdsMap[_msgSender()].push(sourceId);

        if (sourceType == 3) {
            (uint256 promptId, uint256 promptVersion) = GetPromptFromParameterSource(idSourceMap[sourceId]);
            require(promptVersion < idPromptMap[promptId].length, "Source prompt does not exist");
        }

        emit ParameterSourceCreated(_msgSender(), sourceId);
        return sourceId;
    }

    function IsParameterSourceSubstantiated(ParameterSource memory source) internal view returns (bool) {
        if (source.sourceType != 3) {
            return true;
        }
        (uint256 promptId, uint256 promptVersion) = GetPromptFromParameterSource(source);
        Prompt storage prompt = idPromptMap[promptId][promptVersion];
        return prompt.unsubstantiatedParams.length == 0;
    }

    function GetPromptFromParameterSource(ParameterSource memory source) internal pure returns (uint256, uint256) {
        require(source.sourceType == 3, "Only applicable to parameter with type 3");
        uint256 promptId = ReadUInt256FromBytes(source.content, 0);
        uint256 promptVersion = ReadUInt256FromBytes(source.content, 1);
        return (promptId, promptVersion);
    }

    function ReadUInt256FromBytes(bytes memory byteArr, uint256 offset) internal pure returns (uint256) {
        uint256 val = 0;
        for (uint256 i = offset * 32; i < (offset + 1) * 32; ++i) {
            uint8 segment = uint8(byteArr[i]);
            val |= uint256(segment);
            val << 8;
        }
        return val;
    }

    // TODO: implement source type 4: On-Chain Smart Contract Output

    // Chatbot methods
    function CreateChatbot(
        string calldata name,
        string calldata description,
        uint256 promptId,
        uint256 promptVersion,
        ParameterSubstantiation[] memory paramSubstantiations
    ) external returns (uint256) {
        require(bytes(name).length > 0, "Chatbot name must be non-empty");
        require(idPromptMap[promptId].length > 0, "Chatbot prompt does not exist");
        require(promptVersion < idPromptMap[promptId].length, "Chatbot prompt version does not exist");
        require(IsFullySubstantiated(idPromptMap[promptId][promptVersion].unsubstantiatedParams, paramSubstantiations), "Chatbot must have a fully substantiated prompt");

        uint256 chatbotId = nextChatbotId;
        ++nextChatbotId;

        Chatbot storage chatbot = idChatbotMap[chatbotId];
        chatbot.name = name;
        chatbot.description = description;
        chatbot.promptId = promptId;
        chatbot.promptVersion = promptVersion;
        for (uint256 i = 0; i < paramSubstantiations.length; ++i) {
            chatbot.paramSubstantiations.push(paramSubstantiations[i]);
        }

        idChatbotOwnerMap[chatbotId] = _msgSender();
        ownerChatbotIdsMap[_msgSender()].push(chatbotId);

        emit ChatbotCreated(_msgSender(), chatbotId);
        return chatbotId;
    }

    function UpdateChatbotPrompt(
        uint256 chatbotId,
        uint256 newPromptId,
        uint256 newPromptVersion,
        ParameterSubstantiation[] memory newParamSubstantiations
    ) external {
        require(bytes(idChatbotMap[chatbotId].name).length > 0, "Chatbot does not exist");
        require(idChatbotOwnerMap[chatbotId] == _msgSender(), "Only the owner can update the chatbot");
        require(idPromptMap[newPromptId].length > 0, "Chatbot new prompt does not exist");
        require(newPromptVersion < idPromptMap[newPromptId].length, "Chatbot new prompt version does not exist");
        require(IsFullySubstantiated(idPromptMap[newPromptId][newPromptVersion].unsubstantiatedParams, newParamSubstantiations), "Chatbot must have a fully substantiated prompt");

        Chatbot storage chatbot = idChatbotMap[chatbotId];
        chatbot.promptId = newPromptId;
        chatbot.promptVersion = newPromptVersion;

        if (chatbot.paramSubstantiations.length > newParamSubstantiations.length) {
            for (uint256 i = 0; i < newParamSubstantiations.length; ++i) {
                chatbot.paramSubstantiations[i] = newParamSubstantiations[i];
            }
            for (uint256 i = newParamSubstantiations.length; i < chatbot.paramSubstantiations.length; ++i) {
                chatbot.paramSubstantiations.pop();
            }
        }else{
            for (uint256 i = 0; i < chatbot.paramSubstantiations.length; ++i) {
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
        for (uint256 i = 0; i < paramRefs.length; ++i) {
            bool isParamSubstantiated = false;
            for (uint256 j = 0; j < paramRefs.length; ++j) {
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
        if (paramRef.promptVersion != substantiation.promptVersion) {
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
