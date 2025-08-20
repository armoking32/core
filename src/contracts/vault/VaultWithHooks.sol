// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.25;

import "./Vault.sol";

interface IHook {
    function call(
        bytes calldata
    ) external;
}

contract VaultWithHooks is Vault {
    bytes32 public constant SET_HOOK_ROLE = keccak256("SET_HOOK_ROLE");

    address public depositHook;
    address public withdrawHook;
    address public claimHook;

    constructor(
        address delegatorFactory,
        address slasherFactory,
        address vaultFactory
    ) Vault(delegatorFactory, slasherFactory, vaultFactory) {}

    function setHooks(
        address depositHook_,
        address withdrawHook_,
        address claimHook_
    ) external nonReentrant onlyRole(SET_HOOK_ROLE) {
        depositHook = depositHook_;
        withdrawHook = withdrawHook_;
        claimHook = claimHook_;
    }

    function deposit(
        address onBehalfOf,
        uint256 amount
    ) public virtual nonReentrant returns (uint256 depositedAmount, uint256 mintedShares) {
        (depositedAmount, mintedShares) = super.deposit(onBehalfOf, amount);
        address depositHook_ = depositHook;
        if (depositHook_ != address(0)) {
            IHook(depositHook_).call(abi.encode(msg.sender, onBehalfOf, amount, depositedAmount, mintedShares));
        }
    }

    function _withdraw(
        address claimer,
        uint256 withdrawnAssets,
        uint256 burnedShares
    ) internal virtual returns (uint256 mintedShares) {
        address withdrawHook_ = withdrawHook;
        if (withdrawHook_ != address(0)) {
            IHook(withdrawHook_).call(abi.encode(msg.sender, claimer, withdrawnAssets, burnedShares));
        }
        super._withdraw(claimer, withdrawnAssets, burnedShares);
    }

    function _claim(
        uint256 epoch
    ) internal returns (uint256 amount) {
        address claimHook_ = claimHook;
        if (claimHook_ != address(0)) {
            IHook(claimHook_).call(abi.encode(epoch, msg.sender));
        }
        super._claim(epoch);
    }
}
