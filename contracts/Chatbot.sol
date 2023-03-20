// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Context.sol";


// TODO: change the contract name
contract ChatbotContract is Context {

    using Counters for Counters.Counter;

    event ChatbotCreated(address indexed owner, uint256 indexed chatbotId);
    event ChatbotUpdated(uint256 indexed chatbotId, uint256 indexed promptVersion);

    Counters.Counter public _chatbot_id;

    mapping(uint256 => Chatbot) private id2chatbot;
    mapping(uint256 => address) private id2owner;

    // TODO: do we need owner2ids mappping?
    mapping(address => uint256[]) private owner2ids;

    struct Chatbot {
        string name;
        string description;
        uint256 promptId;
        uint256 promptVersion;
    }


    /// @param name chatbot name
    /// @param description chatbot description
    /// @param promptId points to the prompt used by the chatbot
    /// @return a chatbot Id
    function CreateChatbot(string memory name, string memory description,
                               uint256 promptId, uint256 promptVersion)
        public
        returns(uint256)
    {
        uint256 chatbotId = _chatbot_id.current();
        _chatbot_id.increment();

        id2chatbot[chatbotId] = Chatbot(name, description, promptId, promptVersion);
        id2owner[chatbotId] = _msgSender();
        owner2ids[_msgSender()].push(chatbotId);

        emit ChatbotCreated(_msgSender(), chatbotId);
        return chatbotId;
    }


    /// @dev `promptId` & `promptVersion` validity checks are not enforced, offload to application.
    function UpdateChatbotPrompt(uint256 chatbotId, uint256 promptId, uint256 promptVersion)
        public
    {
        address owner = id2owner[chatbotId];
        require(owner == _msgSender(), "Only the owner can update the chatbot.");
        id2chatbot[chatbotId].promptId = promptId;
        id2chatbot[chatbotId].promptVersion = promptVersion;

        emit ChatbotUpdated(chatbotId, promptVersion);
    }

    /// @dev return ('', '', 0, 0) if id is invalid
    function Id2chatbot(uint256 id)
        public
        view
        returns(Chatbot memory)
    {
        return id2chatbot[id];
    }

    /// @dev return zero address if id is invalid
    function Id2owner(uint256 id)
        public
        view
        returns(address)
    {
        return id2owner[id];
    }

    /// @dev return () if id is invalid
    function Owner2ids(address owner)
        public
        view
        returns(uint256[] memory)
    {
        return owner2ids[owner];
    }

}
