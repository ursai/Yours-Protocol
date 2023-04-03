// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Context.sol";

contract URSPromptEngineering is Context {

    // Struct definitions
    struct Prompt {
        string[] params;
        uint256[] paramSourceIds;
        ParameterRef[] unsubstantiatedParams; // auto-generated
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
    uint256 nextPromptId;
    mapping(uint256 => Prompt[]) private idPromptMap;
    mapping(uint256 => address) private idPromptOwnerMap;
    mapping(address => uint256[]) private ownerPromptIdsMap;

    uint256 nextSourceId;
    mapping(uint256 => ParameterSource) private idSourceMap;
    mapping(uint256 => address) private idSourceOwnerMap;
    mapping(address => uint256[]) private ownerSourceIdsMap;

    uint256 nextChatbotId;
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
        require(IsPromptSourceValid(params, paramSourceIds), "Invalid prompt parameter sources");

        uint256 promptId = nextPromptId;
        ++nextPromptId;

        Prompt storage prompt = idPromptMap[promptId].push();
        prompt.params = params;
        prompt.paramSourceIds = paramSourceIds;
        prompt.templateType = templateType;
        prompt.template = template;
        idPromptOwnerMap[promptId] = _msgSender();
        ownerPromptIdsMap[_msgSender()].push(promptId);

        GetUnsubstantiatedParams(idPromptMap[promptId][0], promptId, 0);

        emit PromptCreated(_msgSender(), promptId);
        return promptId;
    }

    function UpdatePrompt(
        uint256 id,
        string[] memory params,
        uint256[] calldata paramSourceIds,
        uint256 templateType,
        string calldata template
    ) external returns (uint256) {
        require(idPromptOwnerMap[id] == _msgSender(), "Only the owner can update the prompt");
        require(IsPromptSourceValid(params, paramSourceIds), "Invalid prompt parameter sources");
        require(idPromptMap[id].length > 0, "Prompt does not exist");

        Prompt storage latestPrompt = idPromptMap[id].push();
        latestPrompt.params = params;
        latestPrompt.paramSourceIds = paramSourceIds;
        latestPrompt.templateType = templateType;
        latestPrompt.template = template;
        uint256 latestVersion = idPromptMap[id].length - 1;
        GetUnsubstantiatedParams(latestPrompt, id, latestVersion);

        Prompt storage previousPrompt = idPromptMap[id][latestVersion - 1];
        for (uint256 i = 0; i < latestPrompt.unsubstantiatedParams.length; ++i) {
            bool isNewUnsubstantiatedSource = true;
            for (uint256 j = 0; j < previousPrompt.unsubstantiatedParams.length; ++j) {
                if (IsSameParameterRef(latestPrompt.unsubstantiatedParams[i], previousPrompt.unsubstantiatedParams[j])) {
                    isNewUnsubstantiatedSource = false;
                    break;
                }
            }
            require(!isNewUnsubstantiatedSource, "Cannot introduce new unsubstantiated parameter sources while updating prompt");
        }

        return latestVersion;
    }

    function IsPromptSourceValid(
        string[] memory params,
        uint256[] calldata paramSourceIds
    ) internal view returns (bool) {
        if (params.length != paramSourceIds.length) {
            return false;
        }
        for (uint256 i = 0; i < params.length; ++i) {
            if (idSourceMap[paramSourceIds[i]].sourceType == 0) {
                return false;
            }
        }
        return true;
    }

    function GetUnsubstantiatedParams(
        Prompt storage targetPrompt,
        uint256 currentPromptId,
        uint256 currentPromptVersion
    ) internal {
        Prompt memory currentPrompt = idPromptMap[currentPromptId][currentPromptVersion];
        for (uint256 i = 0; i < currentPrompt.params.length; ++i) {
            uint256 sourceId = currentPrompt.paramSourceIds[0];
            if (sourceId == 0) {
                targetPrompt.unsubstantiatedParams.push(ParameterRef(currentPromptId, currentPromptVersion, i));
            } else {
                ParameterSource memory source = idSourceMap[sourceId];
                // Source type 3 means the source is another prompt
                // TODO: we should probably add a constant store instead of hard-coding 3 here
                if (source.sourceType == 3)
                {
                    (uint256 sourcePromptId, uint256 sourcePromptVersion) = GetPromptFromParameterSource(source);
                    GetUnsubstantiatedParams(targetPrompt, sourcePromptId, sourcePromptVersion);
                }
            }
        }
    }

    function GetPromptFromParameterSource(ParameterSource memory source) internal pure returns (uint256, uint256) {
        require(source.sourceType == 3, "Only applicable to parameter with type 3");
        uint256 promptId = 0;
        for (uint256 i = 0; i < 32; ++i) {
            uint8 segment = uint8(source.content[i]);
            promptId |= uint256(segment);
            promptId << 8;
        }
        uint256 promptVersion = 0;
        for (uint256 i = 32; i < 64; ++i) {
            uint8 segment = uint8(source.content[i]);
            promptVersion |= uint256(segment);
            promptVersion << 8;
        }
        return (promptId, promptVersion);
    }

    function IsSameParameterRef(
        ParameterRef memory left,
        ParameterRef memory right
    ) internal pure returns (bool)
    {
        return left.promptId == right.promptId &&
            left.promptVersion == right.promptVersion &&
            left.paramIndex == right.paramIndex;
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

        emit ParameterSourceCreated(_msgSender(), sourceId);
        return sourceId;
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
        require(idPromptMap[newPromptId].length > 0, "Chatbot new prompt does not exist");
        require(newPromptVersion < idPromptMap[newPromptId].length, "Chatbot new prompt version does not exist");
        require(IsFullySubstantiated(idPromptMap[newPromptId][newPromptVersion].unsubstantiatedParams, newParamSubstantiations), "Chatbot must have a fully substantiated prompt");

        Chatbot storage chatbot = idChatbotMap[chatbotId];
        chatbot.promptId = newPromptId;
        chatbot.promptVersion = newPromptVersion;
        for (uint256 i = 0; i < newParamSubstantiations.length; ++i) {
            chatbot.paramSubstantiations.push(newParamSubstantiations[i]);
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
