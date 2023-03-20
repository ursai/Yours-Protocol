// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@console.log/console.sol";


// TODO: change the contract name
contract PromptContract is Context {

    // TODO: we can probably just use array and index to store info.
    using Counters for Counters.Counter;

    // TODO: we can include more info in the event if we want to store more info in the local database
    event PromptCreated(address indexed owner, uint256 indexed promptId);
    event PromptUpdated(address indexed owner, uint256 indexed promptId);

    Counters.Counter public _prompt_id;

    mapping(uint256 => Prompt) private id2prompt;
    mapping(uint256 => address) private id2owner;

    // TODO: do we need owner2ids mappping?
    mapping(address => uint256[]) private owner2ids;

    struct Prompt {
        string[] params;
        uint256[] paramSourceIDs;
        string  templateAddr;
    }

    /// @notice inserts a new prompt struct into the mapping
    /// @param params an array of template parameter names
    /// @param paramSourceIDs an array where each element specifies the how each template parameters is to be substantiated
    /// @param templateAddr the address to the off-chain stored prompt template string
    /// @return the prompt Id
    function CreatePrompt(string[] memory params,
                          uint256[] calldata paramSourceIDs,
                          string memory templateAddr)
        public
        returns(uint256)
    {
        uint256 promptId = _prompt_id.current();
        _prompt_id.increment();

        id2prompt[promptId] = Prompt(params, paramSourceIDs, templateAddr);
        id2owner[promptId] = _msgSender();
        owner2ids[_msgSender()].push(promptId);
        emit PromptCreated(_msgSender(), promptId);

        return promptId;
    }


    /// @notice updates the prompt specified by the promptID
    /// @param id the prompt Id
    /// @param params an array of template parameter names
    /// @param paramSourceIDs an array where each element specifies the how each template parameters is to be substantiated
    /// @param templateAddr the address to the off-chain stored prompt template string
    /// @return the new prompt Id
    function UpdatePrompt(uint256 id,
                          string[] memory params,
                          uint256[] calldata paramSourceIDs,
                          string memory templateAddr)
        public
        returns(uint256)
    {
        address owner = id2owner[id];

        require(owner == _msgSender(), "Only the owner can update the prompt.");

        for(uint256 i = 0; i < paramSourceIDs.length; i++){
            require(paramSourceIDs[i] != 0, "updating prompt cannot include source id = 0.");
        }

        uint256 promptId = _prompt_id.current();
        _prompt_id.increment();
        id2prompt[promptId] = Prompt(params, paramSourceIDs, templateAddr);
        id2owner[promptId] = _msgSender();
        owner2ids[_msgSender()].push(promptId);

        emit PromptUpdated(_msgSender(), promptId);
        return promptId;
    }

    function Id2prompt(uint256 id)
        public
        view
        returns(Prompt memory)
    {
        return id2prompt[id];
    }

    function Id2owner(uint256 id)
        public
        view
        returns(address)
    {
        return id2owner[id];
    }

    function Owner2ids(address owner)
        public
        view
        returns(uint256[] memory)
    {
        return owner2ids[owner];
    }
}
