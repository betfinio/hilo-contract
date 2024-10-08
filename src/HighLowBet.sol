// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "openzeppelin/access/Ownable.sol";
import "./shared/BetInterface.sol";

contract DiceBet is Ownable, BetInterface {
    address private immutable player;
    address private immutable game;
    uint256 private immutable amount;
    uint256 private threshold;
    bool private side;
    uint256 private immutable created;
    uint256 winnumber;

    uint256 private status;
    uint256 private result;

    constructor(
        address _player,
        uint256 _amount,
        uint256 _status,
        address _game
    ) {
        created = block.timestamp;
        player = _player;
        amount = _amount;
        status = _status;
        game = _game;
    }

    function getPlayer() external view override returns (address) {
        return player;
    }

    function getGame() external view override returns (address) {
        return game;
    }

    function getAmount() external view override returns (uint256) {
        return amount;
    }

    function getStatus() external view override returns (uint256) {
        return status;
    }

    function getCreated() external view override returns (uint256) {
        return created;
    }

    function getWinNumber() external view returns (uint256) {
        return winnumber;
    }

    function getBets() external view returns (uint256, bool) {
        return (threshold, side);
    }

    function getResult() external view override returns (uint256) {
        return result;
    }

    function getBetInfo()
        external
        view
        override
        returns (address, address, uint256, uint256, uint256, uint256)
    {
        return (player, game, amount, result, status, created);
    }

    function setStatus(uint256 _status) external onlyOwner {
        status = _status;
    }

    function setWinNumber(uint256 _winNumber) external onlyOwner {
        winnumber = _winNumber;
    }

    function setResult(uint256 _result) external onlyOwner {
        result = _result;
    }

    function setBets(uint256 _threshold, bool _side) external onlyOwner {
        threshold = _threshold;
        side = _side;
    }
}
