// SPDX-License-Identifier: MIT

/// @dev solitity version.
pragma solidity >=0.7.0 <0.9.0; //this contract works for solidty version from 0.7.0 to less than 0.9.0

interface IERC20Token {
  function transfer(address, uint256) external returns (bool);
  function approve(address, uint256) external returns (bool);
  function transferFrom(address, address, uint256) external returns (bool);
  function totalSupply() external view returns (uint256);
  function balanceOf(address) external view returns (uint256);
  function allowance(address, address) external view returns (uint256);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Marketplace {

    /// @dev sets the ticket lelnght to zero
    uint internal ticketsLength = 0;

    /// @dev stores the cUsdToken Address
    address internal cUsdTokenAddress = 0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1;

    /* @dev Ticket structure 
* data needed includes: 
* - ``owner``'s address,
* - name of Ticket (ie Mansion, duplex, bungalow,...)
* - description of Event (ie 4bedrooms, 5restooms, 2 swimming pools,...)
* - location of Event (ie CA, USA)
* - price of Ticket
* - sold(Total Number Of Tickets Sold)
* - bought (A bool variable that intialized to false. When set to true, it means the house has been purchased and is off the market.)
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
        bool bought;
        
    }

 /// @dev stores each Ticket created in a list called tickets
    mapping (uint => Ticket) internal tickets;

/// @dev maps the index of item in tickets to a bool value (initialized as false)
    mapping(uint => bool) private exists;

 /// @dev checks if caller is the a ticket owner
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
        string memory _name,
        string memory _image,
        string memory _description, 
        string memory _location, 
        uint _quantity,
        uint _price
        
    ) public {
        uint _sold = 0;
        tickets[ticketsLength] = Ticket(
            payable(msg.sender),
            _name,
            _image,
            _description,
            _location,
            _quantity,
            _sold,
            _price,
            false // bought initialized as false
           
           
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
    function buyTicket(uint _index) public payable  {
         require(
            tickets[_index].owner != msg.sender,
            "You can't buy your own tickets"
        );
        require(
          IERC20Token(cUsdTokenAddress).transferFrom(
            msg.sender,
            tickets[_index].owner,
            tickets[_index].price
          ),
          "Transfer failed."
        );
        tickets[_index].sold++;
         tickets[_index].owner = payable(msg.sender);
    }


        /// @dev allow users to resell or re-list their tickets on the market
    /// @param _price is the new selling price
     function reSellTicket(uint _index, uint _price)
        public
        payable
        exist(_index)
        checkIfTicketOwner(_index)
    {
        tickets[_index].price = _price;
        tickets[_index].bought = false;
    }
    
     /// @dev shows the number of Tickets in the contract
    function getTicketLength() public view returns (uint) {
        return (ticketsLength);
    }
}

































/** 



pragma solidity >=0.7.0 <0.9.0;

interface IERC20Token {
  function transfer(address, uint256) external returns (bool);
  function approve(address, uint256) external returns (bool);
  function transferFrom(address, address, uint256) external returns (bool);
  function totalSupply() external view returns (uint256);
  function balanceOf(address) external view returns (uint256);
  function allowance(address, address) external view returns (uint256);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Marketplace {

    uint internal productsLength = 0;
    address internal cUsdTokenAddress = 0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1;

    struct Product {
        address payable owner;
        string name;
        string image;
        string description;
        string location;
        uint quantity;
        uint sold;
        uint price;
        
    }

    mapping (uint => Product) internal products;

    function writeProduct(
        string memory _name,
        string memory _image,
        string memory _description, 
        string memory _location, 
        uint _quantity,
        uint _price
        
    ) public {
        uint _sold = 0;
        products[productsLength] = Product(
            payable(msg.sender),
            _name,
            _image,
            _description,
            _location,
            _quantity,
            _sold,
            _price
           
           
        );
        productsLength++;
    }

    function readProduct(uint _index) public view returns (
        address payable,
        string memory, 
        string memory, 
        string memory, 
        string memory, 
        uint, 
        uint,
        uint
        
    ) {
        Product storage _Product = products[_index];
        return (
            _Product.owner,
            _Product.name, 
            _Product.image, 
            _Product.description, 
            _Product.location,
             _Product.quantity,
              _Product.sold, 
            _Product.price
           
           
        );
    }

    function buyProduct(uint _index) public payable  {
        require(
          IERC20Token(cUsdTokenAddress).transferFrom(
            msg.sender,
            products[_index].owner,
            products[_index].price
          ),
          "Transfer failed."
        );
        products[_index].sold++;
    }
    
    function getProductsLength() public view returns (uint) {
        return (productsLength);
    }
}

*/