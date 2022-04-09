pragma solidity ^0.8.0;

// remember: to interact with another contract (e.g. ERC20 contracts), we need an interface and the address
// hence, we just import the IERC20 which is interface for ERC20 tokens from openzeppelin
import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol"; // need npm install it also
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";

contract Wallet is Ownable {
    struct Token {
        bytes32 ticker; // e.g. BNB
        address tokenAddress; // we need the address of the token in order to make transfer calls
    }
    mapping(bytes32 => Token) public tokenMapping;
    bytes32[] public tokenList;

    /*
        we need a mapping which supports multiple balances because we can have multiple tokens e.g. ETH,LINK,AAVE, etc... 
        bytes32 is similar to string but we can do more stuff??
        user's wallet address => token symbol => amount/balance e.g. 0x...... => BNB => 10000
    */
    mapping(address => mapping(bytes32 => uint256)) public balances;

    function addToken(bytes32 ticker, address tokenAddress) external onlyOwner {
        tokenMapping[ticker] = Token(ticker, tokenAddress);
        tokenList.push(ticker);
    }

    function deposit(uint256 amount, bytes32 ticker)
        external
        tokenExists(ticker)
    {
        /*transfers from the msg.sender to our wallet (this smart contract address)
        Note: this IERC20 does the check that the user has approve us to spend on his behalf
        and it also checks that we are spending within the allowance */
        IERC20(tokenMapping[ticker].tokenAddress).transferFrom(
            msg.sender,
            address(this),
            amount
        );
        balances[msg.sender][ticker] += amount;
    }

    function withdraw(uint256 amount, bytes32 ticker)
        external
        tokenExists(ticker)
    {
        require(balances[msg.sender][ticker] >= amount, "Insufficient balance");

        balances[msg.sender][ticker] -= amount; //Note: in solidity 0.8.0 above, safemath is built in the compiler and is no longer needed
        // here, we are putting in the token address in the IERC20 interface
        IERC20(tokenMapping[ticker].tokenAddress).transfer(msg.sender, amount);
    }

    function depositEth() external payable {
        balances[msg.sender][bytes32("ETH")] += msg.value;
    }

    function withdrawEth(uint256 amount) external {
        require(
            balances[msg.sender][bytes32("ETH")] >= amount,
            "Insuffient balance"
        );
        balances[msg.sender][bytes32("ETH")] -= amount;
        msg.sender.call{value: amount}(""); //sends to msg.sender the amount
    }

    modifier tokenExists(bytes32 ticker) {
        // if the ticker doesn't address, it is uninitialised. When we call it, it will automatically go to the address(0);
        // hence, this require checks that the ticker has already been added to the tokenList
        require(
            tokenMapping[ticker].tokenAddress != address(0),
            "Token doesn't exist yet. Please add the token first"
        );
        _;
    }
}
