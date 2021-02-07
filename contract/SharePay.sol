// SPDX-License-Identifier: MIT
pragma solidity 0.6.6;
pragma experimental ABIEncoderV2;
import "./IERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.1.0/contracts/math/SafeMath.sol";

contract SharePay {
    using SafeMath for uint256;

    struct Invoice {
        address token; //bnb: 0x1111111111111111111111111111111111111111
        uint256 cost;
        uint256 count;
        address payable[] payers;
        uint8 status; // pending: 0 - done: 1 - reject: 2
        address creator;
    }

    struct tokenData {
        uint256 amount;
        bool active;
    }

    mapping(address => bool) public manager;
    Invoice[] public invoices;

    address[] public tokenPayments;
    mapping(address => tokenData) public tokenPaymentData;

    modifier onlyManager() {
        require(manager[msg.sender] == true, "Only manager");
        _;
    }

    constructor(address _manager) public {
        manager[_manager] = true;
    }

    function addManager(address _manager) external onlyManager {
        manager[_manager] = true;
    }

    function addTokenPayment(address _token) external onlyManager {
        require(_token != address(0), "Token must not be null");
        require(!tokenPaymentData[_token].active, "Token is not added");
        tokenPayments.push(_token);
    }

    function createInvoice(
        address _token,
        uint256 _cost,
        uint256 _count
    ) external onlyManager {
        require(tokenPaymentData[_token].active, "Token must be added");
        invoices.push(
            Invoice(
                _token,
                _cost,
                _count,
                new address payable[](0),
                0,
                msg.sender
            )
        );
    }

    function payWithToken(uint256 _id) external {
        Invoice memory invoice = invoices[_id];
        IERC20(invoice.token).transferFrom(
            msg.sender,
            address(this),
            invoice.cost.div(invoice.count)
        );
        invoice.payers[invoice.payers.length] = (msg.sender);
        if (invoice.payers.length == invoice.count) {
            invoice.status = 1;
        }
    }

    function pay(uint256 _id) external payable {
        Invoice memory invoice = invoices[_id];
        require(msg.value >= invoice.cost.div(invoice.count));
        invoice.payers[invoice.payers.length] = (msg.sender);
        if (invoice.payers.length == invoice.count) {
            invoice.status = 1;
        }
    }

    function reject(uint256 _id) public onlyManager {
        Invoice memory invoice = invoices[_id];
        require(invoice.status == 0, "Invoice is pending");
        if (
            invoice.token == address(0x1111111111111111111111111111111111111111)
        ) {
            for (uint256 i = 0; i < invoice.payers.length; i++) {
                IERC20(invoice.token).transfer(
                    invoice.payers[i],
                    invoice.cost.div(invoice.payers.length)
                );
            }
        } else {
            for (uint256 i = 0; i < invoice.payers.length; i++) {
                invoice.payers[i].transfer(
                    invoice.cost.div(invoice.payers.length)
                );
            }
        }
        invoice.status = 2;
    }

    function getListPayments() public view returns (address[] memory) {
        return tokenPayments;
    }

    function getInvoices() public view returns (Invoice[] memory) {
        return invoices;
    }
}
