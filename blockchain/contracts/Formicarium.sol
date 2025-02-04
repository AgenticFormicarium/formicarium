// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}

contract Formicarium {
    address public owner;
    IERC20 public paymentToken;

    struct Printer {
        address ID;
        string printerDetails;
        address currentOrderId;
    }

    struct Order {
        address ID;
        address printerId;
        address customerId;
        uint256 initialPrice;
        uint256 currentPrice;
        uint256 duration;
        uint256 startTime;
        uint256 expirationTime;
        bool isSigned;
        bool isCompletedProvider;
        bool isUncompleteCustomer;
    }
    address[] public printerAddresses;    

    mapping(address => Printer) public printers;
    mapping(address => Order) public orders;
    mapping(address => address[]) public providerOrders;


    // Modifiers

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier onlyPrinter() {
        require(printers[msg.sender].ID == msg.sender, "Only printer can call this function");
        _;
    }

    // Constructor

    constructor(address _paymentToken) {
        owner = msg.sender;
        paymentToken = IERC20(_paymentToken);
    }

    // Functions

    // Getter functions

    function getAllPrinters() public view returns (Printer[] memory) {
        Printer[] memory allPrinters = new Printer[](printerAddresses.length);
        for (uint256 i = 0; i < printerAddresses.length; i++) {
            allPrinters[i] = printers[printerAddresses[i]];
        }
        return allPrinters;
    }

    // Setter functions

    function registerPrinter(string memory _printerDetails) public {
        require(printers[msg.sender].ID == address(0), "Printer already registered");
        printers[msg.sender] = Printer(msg.sender, _printerDetails, address(0));
        printerAddresses.push(msg.sender);
    }

    function createOrder(address _orderId, address _printerId, uint256 _price, uint256 _duration) public {
        require(orders[_orderId].ID == address(0), "Order already exists");
        require(printers[_printerId].ID == _printerId, "Printer does not exist");
        require(_price > 0, "Price must be greater than 0");
        require(_duration > 0, "Duration must be greater than 0");
        require(paymentToken.balanceOf(msg.sender) >= _price, "Insufficient balance");

        // Ensure sender has approved enough tokens for transfer
        require(paymentToken.allowance(msg.sender, address(this)) >= _price, "Contract not approved to transfer tokens");

        // Transfer tokens from user to smart contract
        require(paymentToken.transferFrom(msg.sender, address(this), _price), "Token transfer failed");

        // remove expired orders
        removeExpiredOrders(_printerId);

        orders[_orderId] = Order(_orderId, _printerId, msg.sender, _price, 0, _duration, 0, block.timestamp + 5 minutes, false, false, true);
        providerOrders[_printerId].push(_orderId);
    }

    function getActiveOrders() public view returns (Order[] memory) {
        address[] storage allOrders = providerOrders[msg.sender];
        uint256 activeCount;

        // First, count active orders to allocate memory efficiently
        for (uint256 i = 0; i < allOrders.length; i++) {
            if (orders[allOrders[i]].isSigned && !orders[allOrders[i]].isCompletedProvider) {
                activeCount++;
            }
        }

        Order[] memory activeOrders = new Order[](activeCount);
        uint256 index = 0;

        for (uint256 i = 0; i < allOrders.length; i++) {
            if (orders[allOrders[i]].isSigned && !orders[allOrders[i]].isCompletedProvider) {
                activeOrders[index++] = orders[allOrders[i]];
            }
        }

        return activeOrders;
    }

    function removeExpiredOrders(address _printerId) internal {
        address[] storage allOrders = providerOrders[_printerId];
        uint256 length = allOrders.length;
        uint256 writeIndex = 0;

        for (uint256 i = 0; i < length; i++) {
            address orderId = allOrders[i];
            if (orders[orderId].isCompletedProvider || orders[orderId].expirationTime < block.timestamp) {
                delete orders[orderId]; // Free storage
            } else {
                allOrders[writeIndex++] = orderId;
            }
        }

        // Trim the array length
        while (allOrders.length > writeIndex) {
            allOrders.pop();
        }
    }

    function signOrder(address _orderId) public onlyPrinter {
        require(orders[_orderId].ID == _orderId, "Order does not exist");
        require(orders[_orderId].printerId == msg.sender, "Only service provider can sign order");
        require(block.timestamp < orders[_orderId].expirationTime, "Order expired");
        require(orders[_orderId].isSigned == false, "Order already signed");
        
        removeExpiredOrders(msg.sender);
        orders[_orderId].isSigned = true;
    }

    function calculateNextOrderId() internal view returns (address) {
        // get active orders by calling getActiveOrders
        Order[] memory activeOrders = getActiveOrders();
        // if there are no active orders, return 0
        if (activeOrders.length == 0) {
            return address(0);
        }
        // calculate the priority factor for each order
        uint256[] memory priorityFactors = new uint256[](activeOrders.length);
        for (uint256 i = 0; i < activeOrders.length; i++) {
            priorityFactors[i] = activeOrders[i].currentPrice / activeOrders[i].initialPrice;
        }
        // find the order with the highest priority factor
        uint256 maxPriority = 0;
        uint256 maxIndex = 0;
        for (uint256 i = 0; i < priorityFactors.length; i++) {
            if (priorityFactors[i] > maxPriority) {
                maxPriority = priorityFactors[i];
                maxIndex = i;
            }
        }
        // return the order ID of the order with the highest priority factor
        return activeOrders[maxIndex].ID;
    }

    function executeNewOrder() public onlyPrinter {
        address _orderId = calculateNextOrderId();
        require(_orderId != address(0), "No active orders to execute");
        orders[_orderId].startTime = block.timestamp;
    }

    function completeOrderProvider(address _orderId) public onlyPrinter {
        require(orders[_orderId].ID == _orderId, "Order does not exist");
        require(orders[_orderId].printerId == msg.sender, "Only service provider can complete order");
        require(orders[_orderId].isSigned, "Order not signed");
        require(orders[_orderId].startTime != 0, "Order not started");
        require(!orders[_orderId].isCompletedProvider, "Order already completed");
        require(block.timestamp < orders[_orderId].startTime + orders[_orderId].duration, "Order duration expired");
        orders[_orderId].isCompletedProvider = true;        
    }

    function reportUncompleteOrder(address _orderId) public {
        require(orders[_orderId].ID == _orderId, "Order does not exist");
        require(orders[_orderId].customerId == msg.sender, "Only customer can confirm order");
        require(orders[_orderId].isSigned, "Order not signed");
        require(orders[_orderId].isCompletedProvider, "Order not completed by provider");
        require(orders[_orderId].isUncompleteCustomer, "Order already reported as uncomplete by customer");
        require(block.timestamp < orders[_orderId].startTime + orders[_orderId].duration + 5 minutes, "Report time expired");

        orders[_orderId].isUncompleteCustomer = false;
    }

    function refundOrderRequest(address _orderId) public {
        require(orders[_orderId].ID == _orderId, "Order does not exist");
        require(orders[_orderId].customerId == msg.sender, "Only customer can refund order request");
        require(!orders[_orderId].isSigned, "Order request already signed");
        require(block.timestamp >= orders[_orderId].expirationTime, "Order request is not expired yet");

        // Transfer tokens back to customer
        require(paymentToken.transfer(msg.sender, orders[_orderId].initialPrice), "Token transfer failed");

        // Free storage
        delete orders[_orderId];
    }

    function transferFundsProivder(address _orderId) public {
        require(orders[_orderId].ID == _orderId, "Order does not exist");
        require(orders[_orderId].printerId == msg.sender, "Only service provider can transfer funds");
        require(orders[_orderId].isSigned, "Order not signed");
        require(orders[_orderId].isCompletedProvider, "Order not completed by provider");
        require(!orders[_orderId].isUncompleteCustomer, "Order reported as uncomplete by customer");
        require(block.timestamp >= orders[_orderId].startTime + orders[_orderId].duration + 5 minutes, "Reporting time not expired yet");

        // Transfer funds to provider
        require(paymentToken.transfer(msg.sender, orders[_orderId].initialPrice), "Token transfer failed");

        // Free storage
        delete orders[_orderId];
    }
}
