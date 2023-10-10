// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20VotesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./Airdrop.sol";
import "./Presale.sol";
import "./ProfitShare.sol";

contract ProfitrocketAI is
    Initializable,
    ERC20Upgradeable,
    ERC20BurnableUpgradeable,
    ERC20PermitUpgradeable,
    ERC20VotesUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    Presale public presale;
    ProfitShare public profitShare;
    Airdrop public airdrop;

    uint256 public investmentPoolTax = 80; // 8%
    uint256 public marketingDevTax = 20; // 2%
    uint256 public totalTax = 100; // Total tax is 10%

    uint256 public sellPercent = 100;
    uint256 public sellPeriod = 24 hours;

    uint256 public antiDumpTax = 100;
    uint256 public antiDumpPeriod = 30 minutes;
    uint256 public antiDumpThreshold = 21;
    bool public antiDumpReserve0 = false;
    uint256 public feeDenominator = 1000;

    address public investmentPoolWallet;
    address public marketingDevWallet;

    uint256 public maxTxAmount = 500000 * 10**18; // Set to 0.5% of total supply as example
    uint256 public maxWalletSize = 2500000 * 10**18; // Set to 2.5% of total supply as example

    mapping(address => bool) public isFeeExempt;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address initialOwner,
        address _investmentPoolWallet,
        address _marketingDevWallet
    ) public initializer {
        __ERC20_init("Profitrocket AI", "PRAI");
        __ERC20Burnable_init();
        __ERC20Permit_init("Profitrocket AI");
        __ERC20Votes_init();
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();

        investmentPoolWallet = _investmentPoolWallet;
        marketingDevWallet = _marketingDevWallet;

        _mint(msg.sender, 1000000000 * 10**decimals());
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    function setFeeExempt(address user, bool exempt) external onlyOwner {
        isFeeExempt[user] = exempt;
    }

    function setinvestmentPoolTax(uint256 newTax) external onlyOwner {
        require(newTax >= 0 && newTax <= 100, "Invalid tax rate");
        investmentPoolTax = newTax;
    }

    function setMarketingDevTax(uint256 newTax) external onlyOwner {
        require(newTax >= 0 && newTax <= 100, "Invalid tax rate");
        marketingDevTax = newTax; // Corrected to marketingDevTax
    }

    function customTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool) {
        require(amount <= maxTxAmount, "Transfer amount exceeds maxTxAmount");
        require(
            balanceOf(recipient) + amount <= maxWalletSize,
            "New balance would exceed maxWalletSize"
        );

        // Detecting a sell (assuming the contract's address is not the owner's address)
        bool isSell = recipient == address(this);

        // Applying extra sell tax if within sell period
        uint256 effectiveSellTax = isSell && block.timestamp < sellPeriod
            ? sellPercent
            : 0;

        // Applying anti-dump tax if sell amount is over the threshold
        uint256 effectiveAntiDumpTax = isSell &&
            amount > antiDumpThreshold * 10**decimals()
            ? antiDumpTax
            : 0;

        // Final tax calculations
        uint256 totalTaxRate = (
            isSell
                ? (investmentPoolTax +
                    marketingDevTax +
                    effectiveSellTax +
                    effectiveAntiDumpTax)
                : (investmentPoolTax + marketingDevTax)
        );
        uint256 taxAmount = (amount * totalTaxRate) / feeDenominator; // Assumes feeDenominator is 1000 for a percent-based rate

        uint256 amountReceived = amount - taxAmount;
        _transfer(sender, recipient, amountReceived);

        if (taxAmount > 0) {
            uint256 investmentPoolTaxAmount = (taxAmount * investmentPoolTax) /
                totalTaxRate;
            uint256 marketingDevTaxAmount = taxAmount - investmentPoolTaxAmount;
            _transfer(sender, investmentPoolWallet, investmentPoolTaxAmount);
            _transfer(sender, marketingDevWallet, marketingDevTaxAmount);
        }
        return true;
    }

    function setSellParameters(uint256 _sellPercent, uint256 _sellPeriod)
        external
        onlyOwner
    {
        sellPercent = _sellPercent;
        sellPeriod = _sellPeriod;
    }

    function setAntiDumpParameters(
        uint256 _antiDumpTax,
        uint256 _antiDumpPeriod,
        uint256 _antiDumpThreshold,
        bool _antiDumpReserve0
    ) external onlyOwner {
        antiDumpTax = _antiDumpTax;
        antiDumpPeriod = _antiDumpPeriod;
        antiDumpThreshold = _antiDumpThreshold;
        antiDumpReserve0 = _antiDumpReserve0;
    }

    function setFeeDenominator(uint256 _feeDenominator) external onlyOwner {
        feeDenominator = _feeDenominator;
    }

    function setMaxTxAmount(uint256 newMaxTxAmount) external onlyOwner {
        maxTxAmount = newMaxTxAmount;
    }

    function setMaxWalletSize(uint256 newMaxWalletSize) external onlyOwner {
        maxWalletSize = newMaxWalletSize;
    }

    function _update(
        address from,
        address to,
        uint256 value
    ) internal override(ERC20Upgradeable, ERC20VotesUpgradeable) {
        super._update(from, to, value);
    }

    function nonces(address owner)
        public
        view
        override(ERC20PermitUpgradeable, NoncesUpgradeable)
        returns (uint256)
    {
        return super.nonces(owner);
    }
}