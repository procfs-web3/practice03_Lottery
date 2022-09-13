// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Lottery {

    struct Buyers {
        bool is_valid;
        address[] buyerAddresses;
    }

    enum LotteryPhase { SellingPhase, DrawingPhase, ClaimingPhase }
    mapping(uint16 => Buyers) public buyers;
    uint public lotteryBalance = 0;
    uint nPlayers;
    uint beginTimestamp;
    uint16 _winningNumber;
    bool winningNumberDetermined = false;

    function getLotteryPhase() view internal returns (LotteryPhase) {
        if (block.timestamp >= beginTimestamp + 24 hours) {
            if (winningNumberDetermined) {
                return LotteryPhase.ClaimingPhase;
            }
            else {
                return LotteryPhase.DrawingPhase;
            }
        }
        else {
            return LotteryPhase.SellingPhase;
        }
    }

    function reset() internal {
        beginTimestamp = block.timestamp;
        winningNumberDetermined = false;
        nPlayers = 0;
    }

    constructor() {
        reset();
    }

    function buy(uint16 number) external payable {
        require(getLotteryPhase() == LotteryPhase.SellingPhase, "");
        require(msg.value == 0.1 ether, "");
        Buyers storage b = buyers[number];
        if (b.is_valid) {
            for (uint i = 0; i < b.buyerAddresses.length; i++) {
                require(b.buyerAddresses[i] != msg.sender, "");
            }
            b.buyerAddresses.push(msg.sender);
        }
        else {
            b.is_valid = true;
            b.buyerAddresses.push(msg.sender);
        }
        lotteryBalance += 0.1 ether;
        nPlayers++;
    }

    function draw() external {
        require(getLotteryPhase() == LotteryPhase.DrawingPhase, "");
        winningNumberDetermined = true;
        _winningNumber = 1337;
    }

    function claim() external {
        require(getLotteryPhase() == LotteryPhase.ClaimingPhase, "");
        nPlayers--;
        if (buyers[_winningNumber].is_valid) {
            uint winnersCnt = buyers[_winningNumber].buyerAddresses.length;
            uint share = lotteryBalance / winnersCnt;
            for (uint i = 0; i < winnersCnt; i++) {
                address payable winner = payable(buyers[_winningNumber].buyerAddresses[i]);
                if (winner == msg.sender) {
                    winner.call{value: share}("");
                    lotteryBalance -= share;
                    buyers[_winningNumber].buyerAddresses[i] = buyers[_winningNumber].buyerAddresses[winnersCnt-1];
                    buyers[_winningNumber].buyerAddresses.pop();
                    break;
                }
            }
            
        }
        if (nPlayers == 0) {
            reset();
        }
    }

    function winningNumber() public view returns (uint16) {
        return _winningNumber;
    }
}