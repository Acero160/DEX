// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Dex {

    //Struct
    struct Token {
        string ticker; //Title of the token
        address tokenAddress; //Address of the token

    }

    //Struct of the order
    struct Order {
        uint id; //Id of the order
        address trader; //Address of the trader
        Side side; //Buy or sell
        uint amount; //Amount of token
        uint price; //Price of the token
        uint filled; //Amount of tokens filled
        uint date; //Date of the order
    }



    //Variables
    address public admin;
    string constant DAI = "DAI"; // To spend less gas in future transactions
    //Variable of the order
    uint public nextOrderId = 0; //Id of the next order
    //Variable market order
    uint nextTradeId; //Id of the next trade



    //Array
    string [] public tokenList; //List of tokens
    

    //Mapping
    mapping(string => Token) public tokens; //Mapping of tokens
    mapping(address => mapping(string => uint)) public balances; //Mapping of balances
    //MApping of the order book
    mapping (string => mapping (uint => Order[])) public orderBook; //Mapping of the order book

    //Modifiers
    modifier onlyAdmin {
        require(msg.sender == admin, "Only admin can interact");
        _;
    }

    modifier tokenExist (string memory ticker) {
        require (tokens [ticker].tokenAddress  != address(0), "Token does not exist");
        _;
    }


    //Events
    event NewTrade (
        uint trade, 
        uint orderId,
        string indexed ticker,
        address indexed trader1,
        address indexed trader2,
        uint amount,
        uint price,
        uint date
    );

    constructor () {
        admin = msg.sender;
    }



    //Functions
    function addToken (string memory ticker, address tokenAddress) external onlyAdmin {
        tokens[ticker] = Token(ticker, tokenAddress);
        tokenList.push(ticker);
    }

     function removeToken (string memory ticker) external onlyAdmin {
        tokens[ticker] = Token ('', address(0));
    }

    //Function to add liquidity
    function deposit (uint _amount, string memory ticker) external tokenExist(ticker) {
        IERC20(tokens[ticker].tokenAddress).transferFrom(msg.sender, address(this), _amount);
        balances[msg.sender] [ticker] += _amount;
    }

    function withdraw  (uint _amount, string memory ticker) external tokenExist(ticker) {
        require (balances[msg.sender][ticker] >= _amount, "Not enough tokens");
        balances[msg.sender] [ticker] -= _amount;
        IERC20(tokens[ticker].tokenAddress).transfer(msg.sender, _amount);
    }

    // Creation of limit orders
    enum Side {
        BUY,
        SELL
    }

    //Funtions of order limits
    function createLimitOrder (string memory ticker, uint amount, uint price, Side side) external tokenExist(ticker) {
        if (side == Side.SELL) {
            // If it is a sale, we will check if the user has enough tokens
            require (balances[msg.sender][ticker] >= amount, "Not enough tokens");
        } else {
            require(balances[msg.sender][DAI] >= amount * price, "Not enough DAI");
        }
    

         // Get list of orders
        Order [] storage orders = orderBook[ticker][uint(side)]; // uint side indicates the position of the enum
        orders.push(Order(nextOrderId, msg.sender, side, amount, 0, price, block.timestamp));

        // We will need to sort the orderBook by price, from highest to lowest, using the algorithm
        uint i = orders.length - 1;
        while (i > 0) {
            if (side == Side.BUY && orders[i - 1].price > orders[i].price) { 
            break;
            }
            if (side == Side.SELL && orders[i - 1].price < orders[i].price) {
            break;
         }
            Order memory order = orders[i - 1];
            orders[i - 1] = orders[i];
            orders[i] = order;
            i--;
         } // We continue until it breaks in the ifs or until the while loop ends
         nextOrderId++;
    }

    //Function to create market orders
    function createMarketOrder(string memory ticker, uint amount, Side side) external tokenExist(ticker) {
        if(side == Side.SELL) {
            // If it is a sale, we will check if the user has enough tokens
            require(balances[msg.sender][ticker] >= amount, "Not enough tokens");
        } 
        Order[] storage orders = orderBook [ticker] [uint (side == Side.BUY ? Side.SELL : Side.BUY)];
        uint i;
        uint remaining = amount;

        //Iterate through the orders until all of them are completed
        while (i < orders.length && remaining > 0) { // We will iterate through the orders until the remaining amount is 0
            // Get how much DAI is available
            uint available = orders[i].amount - orders[i].filled; //Get the amount of the order that is available
            uint matched = (remaining > available) ? available : remaining; // Get the minimum between the remaining amount and the available amount
            remaining -= matched; // Subtract the matched amount from the remaining amount
            orders[i].filled += matched; // Add the matched amount to the filled amount of the order

            emit NewTrade (nextTradeId, orders[i].id, ticker, orders[i].trader, msg.sender, matched, orders[i].price, block.timestamp);

            if (side == Side.SELL) {
                balances[msg.sender][ticker] -= matched; // Subtract the matched amount from the seller's balance
                balances[msg.sender][DAI] += matched * orders[i].price; // Add the matched amount to the seller's DAI balance
                balances[orders[i].trader][ticker] += matched;   // Add the matched amount to the buyer's balance
                balances[orders[i].trader][DAI] -= matched * orders[i].price; // Subtract the matched amount from the buyer's DAI balance
            } else {
                // It's possible that the buyer doesn't have enough DAI to make the purchase
                require(balances[msg.sender][DAI] >= matched * orders[i].price, "Not enough DAI");
                balances[msg.sender][ticker] += matched;
                balances[msg.sender][DAI] -= matched * orders[i].price; 
                balances[orders[i].trader][ticker] -= matched;
                balances[orders[i].trader][DAI] += matched * orders[i].price;
            }
            nextTradeId++;
            i++;
        }

        // Remove the completed orders to optimize the Smart Contract
            i = 0;
            while (i < orders.length && orders[i].filled == orders[i].amount) {
             // Need to shift all the orders to the left and remove the last one
             for (uint j = i; j < orders.length - 1; j++) {
                orders[j] = orders[j + 1];
            } 
            //Remove the last one
            orders.pop();
            i++;
        }
    }

    // Function to get the orders and the tokens
    function getOrders (string memory ticker, Side side) external view returns (Order [] memory) {
        return orderBook[ticker][uint(side)];
    }

    function getTokens () external view returns (Token [] memory) {
        // Create a new array of tokens
        Token [] memory _tokens = new Token [] (tokenList.length);
        for (uint i = 0; i < tokenList.length; i++) {
         _tokens[i] = Token (
            tokens[tokenList[i]].ticker,
            tokens[tokenList[i]].tokenAddress
         );
        }
        return _tokens;
    }

}
