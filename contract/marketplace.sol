// SPDX-License-Identifier: MIT

/// @dev solitity version.
pragma solidity >=0.7.0 <0.9.0; //this contract works for solidty version from 0.7.0 to less than 0.9.0

interface IERC20Token {
    function transfer(address, uint256) external returns (bool);

    function approve(address, uint256) external returns (bool);

    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address) external view returns (uint256);

    function allowance(address, address) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract Marketplace {
    event NewRequest(uint index, uint requestId, uint quantity, string reason);
    event RejectRequest(uint requestId);
    event ApproveRequest(uint requestId, uint quantity, uint index);

    /// @dev sets the ticket lelnght to zero
    uint private ticketsLength;

    uint private requestsLength;

    address public admin;

    /// @dev stores the cUsdToken Address
    address internal cUsdTokenAddress =
        0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1;

    /**
     *  @dev Ticket structure
     * data needed includes:
     * - ``owner``'s address,
     * - name of Ticket (i.e Mansion, duplex, bungalow,...)
     * - description of Event (i.e 4bedrooms, 5restooms, 2 swimming pools,...)
     * - location of Event (i.e CA, USA)
     * - price of Ticket
     * - sold(Total Number Of Tickets Sold)
     * - soldOut (A bool variable that intialized to false. When set to true, it means the house has been purchased and is off the market.)
     */

    struct Ticket {
        address payable owner;
        string name;
        string image;
        string description;
        string location;
        uint quantity;
        uint sold;
        uint price;
        bool soldOut;
    }

    struct RequestReStock {
        uint ticketId;
        string reason;
        uint amount;
    }

    /// @dev stores each Ticket created in a mapping called tickets
    mapping(uint => Ticket) private tickets;

    mapping(uint => RequestReStock) private requests;

    /// @dev maps the index of item in tickets to a bool value (initialized as false)
    mapping(uint => bool) private exists;

    constructor() {
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(admin == msg.sender, "Caller isn't admin");
        _;
    }

    modifier checkQuantity(uint _quantity) {
        require(_quantity > 0, "Quantity needs to be greater than zero");
        _;
    }

    /// @dev checks if caller is the ticket owner
    modifier checkIfTicketOwner(uint _index) {
        require(tickets[_index].owner == msg.sender, "Unauthorized caller");
        _;
    }

    /// @dev checks ticket(_index) exists
    modifier exist(uint _index) {
        require(exists[_index], "Query of nonexistent house");
        _;
    }

    /// @dev allow users to add a ticket to the marketplace
    function ListEventTicket(
        string calldata _name,
        string calldata _image,
        string calldata _description,
        string calldata _location,
        uint _quantity,
        uint _price
    ) public checkQuantity(_quantity) {
        require(bytes(_name).length > 0, "Empty name");
        require(bytes(_image).length > 0, "Empty image");
        require(bytes(_description).length > 0, "Empty description");
        require(bytes(_location).length > 0, "Empty location");
        require(_price > 0, "Price can't be zero");
        tickets[ticketsLength] = Ticket(
            payable(msg.sender),
            _name,
            _image,
            _description,
            _location,
            _quantity,
            0, // sold initialized as zero
            _price,
            false // soldOut initialized as false
        );
        exists[ticketsLength] = true;
        ticketsLength++;
    }

    /// @dev allow users view details of Ticket
    function viewEventTicket(uint _index)
        public
        view
        exist(_index)
        returns (Ticket memory)
    {
        return (tickets[_index]);
    }

    /// @dev allow users to buy a ticket on sale
    /// @notice current ticket owners can't buy their own ticket
    function buyTicket(uint _index) public payable exist(_index) {
        Ticket storage currentTicket = tickets[_index];
        require(
            currentTicket.owner != msg.sender,
            "You can't buy your own tickets"
        );
        require(!currentTicket.soldOut, "Tickets are sold out");
        currentTicket.quantity--;
        currentTicket.sold++;
        if (currentTicket.quantity == 0) {
            currentTicket.soldOut = true;
        }
        require(
            IERC20Token(cUsdTokenAddress).transferFrom(
                msg.sender,
                currentTicket.owner,
                currentTicket.price
            ),
            "Transfer failed."
        );
    }

    /**
     *  @dev allow events' owners to add create a request to restock the ticket amount for their event
     *  @notice a valid reason for restocking needs to be provided
     */
    function requestRestock(
        uint _index,
        uint _quantity,
        string calldata _reason
    )
        public
        payable
        exist(_index)
        checkIfTicketOwner(_index)
        checkQuantity(_quantity)
    {
        uint requestId = requestsLength;
        requestsLength++;
        requests[requestId] = RequestReStock(_index, _reason, _quantity);

        emit NewRequest(_index, requestId, _quantity, _reason);
    }

    /// @dev allows the admin to approve a restock request
    function approveRestockRequest(uint requestId) public onlyAdmin {
        RequestReStock storage currentRequest = requests[requestId];
        Ticket storage currentTicket = tickets[currentRequest.ticketId];
        uint newQuantity = currentTicket.quantity + currentRequest.amount;
        currentTicket.quantity = newQuantity;
        if (currentTicket.soldOut) {
            currentTicket.soldOut = false;
        }
        emit ApproveRequest(
            requestId,
            currentRequest.amount,
            currentRequest.ticketId
        );
    }

    /// @dev allows the admin to reject a restock request
    function rejectRestockRequest(uint requestId) public onlyAdmin {
        requests[requestId] = requests[requestsLength - 1];
        delete requests[requestsLength - 1];
        requestsLength--;
        emit RejectRequest(requestId);
    }

    /// @dev shows the number of Tickets in the contract
    function getTicketsLength() public view returns (uint) {
        return (ticketsLength);
    }

    /// @dev shows the number of requests in the contract
    function getRequestsLength() public view returns (uint) {
        return (requestsLength);
    }
}
