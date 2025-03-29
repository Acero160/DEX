# 🦄 Decentralized Exchange (DEX) 

## 📑 Overview
The **Decentralized Exchange (DEX)** allows users to trade tokens in a decentralized manner. This smart contract enables the creation of buy and sell orders, liquidity deposit/withdrawal, and market orders. The contract supports multiple tokens, offering flexibility and secure trading on the Ethereum network.
---
## 💡 Key Features
- **Token Support**: Add and remove tokens (ERC20 tokens supported).
- **Liquidity Management**: Deposit and withdraw tokens easily.
- **Order Book**: Users can create buy or sell limit orders, and also place market orders for token trading.
- **Market Efficiency**: Automated trade execution with matching orders from the order book.
- **Admin Control**: Only the admin can add or remove tokens from the exchange.
----
 ## Contract Overview
📜 Dex.sol (Main Contract)
The contract consists of the following components:

- **Structs:**
Token: Stores information about each token (ticker and address).

- **Order:** Defines an order's details (id, trader address, side, amount, price, and fill status).

- **Variables:**
  - admin: The address of the admin who can add/remove tokens.

- nextOrderId: Auto-incremented ID for orders.

- nextTradeId: Auto-incremented ID for trades.

- tokenList: A list of available tokens.

- tokens: A mapping of token tickers to token information.

- balances: A mapping of user balances for each token.

- **Modifiers:**
  - onlyAdmin: Ensures that only the admin can execute certain actions.

  - tokenExist: Ensures the token exists before executing actions.

- **Events:**
  - NewTrade: Emitted when a new trade occurs between two users.

## 🔨 Key Functions
- addToken(): Adds a new token to the exchange (only accessible by admin).

- removeToken(): Removes a token from the exchange (only accessible by admin).

- deposit(): Deposits tokens into the exchange, increasing the user’s balance.

- withdraw(): Withdraws tokens from the exchange, decreasing the user’s balance.

- createLimitOrder(): Creates a limit order for buying or selling tokens.

- createMarketOrder(): Executes a market order by matching existing limit orders.

- getOrders(): Returns the current orders for a specific token and side (buy/sell).

- getTokens(): Returns the list of available tokens on the exchange.
