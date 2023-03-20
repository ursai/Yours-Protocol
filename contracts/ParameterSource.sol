// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Context.sol";


// TODO: change the contract name
// TODO: can we combine prompt contract and parameterSource contracts?

/// @notice The prompt parameter source contract maintains a mapping of
/// @notice parameter source IDs to ParameterSource structs,
/// @notice and maintains a self-incrementing counter used to generate the next parameter source ID.
contract ParameterSourceContract is Context {

    using Counters for Counters.Counter;
    Counters.Counter public _source_id;

    event PromptParameterSourceCreated(address indexed owner, uint256 indexed sourceId);

    struct ParameterSource {
        string SourceType;
        string content;
    }

    mapping(uint256 => ParameterSource) public id2source;
    mapping(uint256 => address) public id2owner;

    // TODO: do we need owner2ids mappping?
    mapping(address => uint256[]) public owner2ids;

    // omit constructor
    // constructor(){}


    /// @param sourceType indicates the type of the parameter source
    /// @param content a sequence of bytes to be interpreted differently depending on param-source type
    /// @return a parameter source id
    /// @dev we may have duplicated (sourceType, content)
    function CreatePromptParameterSource(string memory sourceType, string memory content)
        public
        returns(uint256)
    {
        uint256 sourceId = _source_id.current();
        _source_id.increment();
        id2source[sourceId] = ParameterSource(sourceType, content);
        id2owner[sourceId] = _msgSender();
        owner2ids[_msgSender()].push(sourceId);

        emit PromptParameterSourceCreated(_msgSender(), sourceId);

        return sourceId;
    }


    /// @dev if `id` is invalid return ('', '')
    function Id2source(uint256 id)
        public
        view
        returns(ParameterSource memory)
    {
        return id2source[id];
    }

    /// @dev if `id` is invalid return zero address
    function Id2owner(uint256 id)
        public
        view
        returns(address)
    {
        return id2owner[id];
    }

    /// @dev if `owner` is invalid return ()
    function Owner2ids(address owner)
        public
        view
        returns(uint256[] memory)
    {
        return owner2ids[owner];
    }
}
