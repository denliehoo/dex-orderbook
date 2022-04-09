pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2; // required for returning structs

import "./wallet.sol";

// our Dex inherits from the wallet contract
contract Dex is Wallet {
    /* enum is like a custom variable that has different properties
    It is similar to booleans but with custom values instead, also it can have
    more than 2 options if we want
    Under the surface, the first option would be a uint 0 , 2nd would be uint 1,....
    Hence, here, buy would be a uint 0 and sell would be a uint 1 */

    enum Side {
        BUY,
        SELL
    }

    struct Order {
        uint256 id;
        address trader;
        Side side; // order.side = Side.BUY
        bytes32 ticker;
        uint256 amount;
        uint256 price;
        uint256 filled;
    }

    uint256 public nextOrderId = 0;

    // ticker => 0 / 1 (as in the enum Side: BUY(uint 0) or SELL(uint 1)) => array of all the Orders
    // thus, what this means is that each ticker(asset) will have two set of orderbooks (buy or sell)
    // and each of this order book, it would contain an array of orders
    mapping(bytes32 => mapping(uint256 => Order[])) public orderBook;

    // side as in BUY or SELL
    // e.g. getOrderBook(bytes32("LINK"), Side.BUY)
    function getOrderBook(bytes32 ticker, Side side)
        public
        view
        returns (Order[] memory)
    {
        return orderBook[ticker][uint256(side)];
    }

    /* requires sorting. Best price should always be first in the order book.
    Check again...
    If on buy side, highest price should be at the top of the order book (highest to lowest)
    If on sell side, loweest price should be at the lower of the order book (lowest to highest)
    Hence, the 0 index should be filled first??
    */
    function createLimitOrder(
        Side side,
        bytes32 ticker,
        uint256 amount,
        uint256 price
    ) public {
        if (side == Side.BUY) {
            // buying ERC20 token for ETH
            require(balances[msg.sender]["ETH"] >= amount * price);
        } else if (side == Side.SELL) {
            // selling ERC20 token for ETH
            require(balances[msg.sender][ticker] >= amount);
        }

        // gets the orderbook
        Order[] storage orders = orderBook[ticker][uint256(side)];
        //pushes into the orderbook; remember: if its storage, then
        // when we push, even out is pushed in too
        orders.push(
            Order(nextOrderId, msg.sender, side, ticker, amount, price, 0)
        );

        //Bubble sort
        // if orders.length is more than 0, i is orders.length -1
        // if orders.length = 0 (orders array is empty) then i = 0
        uint256 i = orders.length > 0 ? orders.length - 1 : 0;
        if (side == Side.BUY) {
            // sort highest to lowest
            while (i > 0) {
                if (orders[i - 1].price > orders[i].price) {
                    break;
                }
                Order memory orderToMove = orders[i - 1];
                orders[i - 1] = orders[i];
                orders[i] = orderToMove;
                i--;
            }
        } else if (side == Side.SELL) {
            // sort lowest to highest
            while (i > 0) {
                if (orders[i - 1].price < orders[i].price) {
                    break;
                }
                Order memory orderToMove = orders[i - 1];
                orders[i - 1] = orders[i];
                orders[i] = orderToMove;
                i--;
            }
        }

        nextOrderId++;
    }

    function createMarketOrder(
        Side side,
        bytes32 ticker,
        uint256 amount
    ) public {
        if (side == Side.SELL) {
            require(
                balances[msg.sender][ticker] >= amount,
                "Insuffient balance"
            );
        }

        uint256 orderBookSide;
        if (side == Side.BUY) {
            orderBookSide = 1;
        } else {
            orderBookSide = 0;
        }
        Order[] storage orders = orderBook[ticker][orderBookSide];

        uint256 totalFilled = 0;

        /*loop stops if i < ordes.length (as in whole order book has been looped)
         or if totalFilled is equal amount. We use && because for loops, the 2nd part
         is the condition and the loop keeps running as long as the condition is true.
         Remember: true && false => false   ; true || false => true. 
         If, we use || (OR) instead, if one of the condition becomes false, the 2nd part is still true and loop continues.
         Hence, we use && (AND) since if either one of the conditions becomes false, the 2nd part becomes false and loop stops
         */
        for (uint256 i = 0; i < orders.length && totalFilled < amount; i++) {
            uint256 leftToFill = amount - (totalFilled);
            uint256 availableToFill = orders[i].amount - (orders[i].filled);
            uint256 filled = 0;
            if (availableToFill > leftToFill) {
                filled = leftToFill; //Fill the entire market order
            } else {
                filled = availableToFill; //Fill as much as is available in order[i]
            }

            totalFilled += (filled);
            orders[i].filled += (filled);
            uint256 cost = filled * (orders[i].price);

            // executes the trade and shifts balance between buyer/seller
            if (side == Side.BUY) {
                //Verify that the buyer has enough ETH to cover the purchase (require)
                require(balances[msg.sender]["ETH"] >= cost);
                //msg.sender is the buyer
                // reduce ETH balance & increase purchased asset balance of buyer
                balances[msg.sender][ticker] += (filled);
                balances[msg.sender]["ETH"] -= (cost);
                // increase ETH balance & reduce balance of the asset that buyer purchased of the seller
                balances[orders[i].trader][ticker] -= (filled);
                balances[orders[i].trader]["ETH"] += (cost);
            } else if (side == Side.SELL) {
                //Msg.sender is the seller
                balances[msg.sender][ticker] -= (filled);
                balances[msg.sender]["ETH"] += (cost);

                balances[orders[i].trader][ticker] += (filled);
                balances[orders[i].trader]["ETH"] -= (cost);
            }
        }
        /* 
        Once Out of the loop, we loop through the orderbook
         to remove any orders that are 100% filled. 
         Usually the filled orders will be at the top of the orderbook (i.e. index 0,1..) because thats the "best price'
         We stop the loop once either orders.length is 0 as in orderbook is empty; OR;
         when orders[0] (which is the top of the order book)'s filled amount is not equal to order amount,
         meaning that the order is either only partially filled or not filled at all
        e.g.[Order(amount=10, filled = 10), Order(amount=100, filled = 100),
        Order(amount=25, filled = 10),Order(amount=200, filled = 0)]
         */
        while (orders.length > 0 && orders[0].filled == orders[0].amount) {
            /*
            Remove the top element in the orders array by overwriting every element
            with the next element in the order list; basically what this means is that
            we take the 0th index and replace it with the 1st index. Then we take the 1st index
            and replace it with the 2nd index and so on. At the end, the last 2 index will be a
            duplicate of each other, then we pop to last index (which is a duplicate) and remove it.

            Hence, in the above example, it would be (amount=10,filled=10) being replaced with (a=100,f=100)
            And then at thee end of the loop, the last 2 index would be (a=200,f=0), then the last index
            which is the duplicate is removed. Hence, we successfully removed the 0th index Order(a=10,f=10) from the array. 
            Note: the loop stops at orders.length -1 because at the last index, there would be no i+1 if we stop
            at orders.length. 
            */
            for (uint256 i = 0; i < orders.length - 1; i++) {
                orders[i] = orders[i + 1];
            }
            orders.pop();
        }
    }
}
