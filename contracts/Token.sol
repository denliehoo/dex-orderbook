pragma solidity ^0.8.0;
import "../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";

// simulating that the token is Link as in chainlink; can be any other token
contract Link is ERC20 {
    constructor() ERC20("Chainlink", "LINK") {
        _mint(msg.sender, 1000);
    }
}
