// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IERC20 {
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

abstract contract Ownable {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Ownable: caller is not the owner");
        _;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Ownable: zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        address previousOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(previousOwner, newOwner);
    }
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status = _NOT_ENTERED;

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

contract TaskWiserBatchPayments is Ownable, ReentrancyGuard {
    /// @notice Tokens allowed for batch payments
    mapping(address => bool) public supportedTokens;

    uint256 public constant MAX_BATCH = 200;

    event SupportedTokenUpdated(address indexed token, bool allowed);
    event BatchPaymentExecuted(
        address indexed token,
        address indexed payer,
        address indexed caller,
        uint256 recipientsCount
    );

    constructor(address twusdc, address twusdt) {
        require(twusdc != address(0) && twusdt != address(0), "Invalid token address");

        supportedTokens[twusdc] = true;
        supportedTokens[twusdt] = true;

        emit SupportedTokenUpdated(twusdc, true);
        emit SupportedTokenUpdated(twusdt, true);
    }

    /// @notice Owner can enable or disable ERC20 tokens
    function setSupportedToken(address token, bool allowed) external onlyOwner {
        require(token != address(0), "Invalid token");
        supportedTokens[token] = allowed;
        emit SupportedTokenUpdated(token, allowed);
    }

    /// @notice Anyone can call batchPay now (no operators)
    function batchPay(
        address token,
        address payer,
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external nonReentrant {
        require(supportedTokens[token], "Token not supported");

        // If payer is not provided, default to msg.sender
        if (payer == address(0)) {
            payer = msg.sender;
        }

        uint256 length = recipients.length;
        require(length > 0 && length == amounts.length, "Invalid payload");
        require(length <= MAX_BATCH, "Batch too large");

        IERC20 erc20 = IERC20(token);

        for (uint256 i = 0; i < length; ++i) {
            require(recipients[i] != address(0), "Recipient is zero");
            require(amounts[i] > 0, "Amount is zero");

            bool ok = erc20.transferFrom(payer, recipients[i], amounts[i]);
            require(ok, "Transfer failed");
        }

        emit BatchPaymentExecuted(token, payer, msg.sender, length);
    }

    /// @notice Owner can rescue tokens accidentally sent to contract
    function rescueTokens(address token, uint256 amount, address to) external onlyOwner {
        require(to != address(0), "Invalid recipient");
        bool ok = IERC20(token).transferFrom(address(this), to, amount);
        require(ok, "Rescue failed");
    }
}
