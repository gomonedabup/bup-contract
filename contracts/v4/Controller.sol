//SPDX-License-Identifier: Unlicense
pragma solidity ^0.4.11;

contract AbstractSweeper {
    function sweep(address token, uint256 amount) returns (bool);

    function() {
        throw;
    }

    Controller controller;

    function AbstractSweeper(address _controller) {
        controller = Controller(_controller);
    }

    modifier canSweep() {
        if (
            msg.sender != controller.authorizedCaller() &&
            msg.sender != controller.owner()
        ) throw;
        if (controller.halted()) throw;
        _;
    }
}

contract Token {
    function balanceOf(address a) returns (uint256) {
        (a);
        return 0;
    }

    function transfer(address a, uint256 val) returns (bool) {
        (a);
        (val);
        return false;
    }
}

/**
 * 토큰 전송 컨트랙트
 * 입금용 사용자 지갑에서 요청되어 처리
 * 표준화된 토큰 전송
 */
contract DefaultSweeper is AbstractSweeper {
    function DefaultSweeper(address controller) AbstractSweeper(controller) {}

    /**
     * 관리 사용자 계정으로 토큰 전송
     * 컨트랙트 배포자 -> 관리 사용자로 지정되어 있음
     */
    function sweep(address _token, uint256 _amount) canSweep returns (bool) {
        bool success = false;
        address destination = controller.destination();

        if (_token != address(0)) {
            Token token = Token(_token);

            uint256 amount = _amount;
            if (amount > token.balanceOf(this)) {
                return false;
            }

            success = token.transfer(destination, amount);
        } else {
            uint256 amountInWei = _amount;
            if (amountInWei > this.balance) {
                return false;
            }

            success = destination.send(amountInWei);
        }

        if (success) {
            controller.logSweep(this, destination, _token, _amount);
        }

        return success;
    }
}

/**
 * 입금용 사용자 지갑 컨트랙트
 */
contract UserWallet {
    AbstractSweeperList sweeperList;

    function UserWallet(address _sweeperlist) {
        sweeperList = AbstractSweeperList(_sweeperlist);
    }

    function() public payable {}

    function tokenFallback(
        address _from,
        uint256 _value,
        bytes _data
    ) {
        (_from);
        (_value);
        (_data);
    }

    /**
     * 토큰 관리용 계정을 전송
     * 토큰 전송을 위해 sweeper에게 요청함(DefaultSweeper)
     */
    function sweep(address _token, uint256 _amount) returns (bool) {
        (_amount);
        return sweeperList.sweeperOf(_token).delegatecall(msg.data);
    }
}

contract AbstractSweeperList {
    function sweeperOf(address _token) returns (address);
}

contract Controller is AbstractSweeperList {
    address public owner;
    address public authorizedCaller;

    address public destination;

    bool public halted;

    event LogNewWallet(address receiver);
    event LogSweep(
        address indexed from,
        address indexed to,
        address indexed token,
        uint256 amount
    );

    modifier onlyOwner() {
        if (msg.sender != owner) throw;
        _;
    }

    modifier onlyAuthorizedCaller() {
        if (msg.sender != authorizedCaller) throw;
        _;
    }

    modifier onlyAdmins() {
        if (msg.sender != authorizedCaller && msg.sender != owner) throw;
        _;
    }

    function Controller() {
        owner = msg.sender;
        destination = msg.sender; // 토큰 관리용 사용자 계정
        authorizedCaller = msg.sender;
    }

    function changeAuthorizedCaller(address _newCaller) onlyOwner {
        authorizedCaller = _newCaller;
    }

    function changeDestination(address _dest) onlyOwner {
        destination = _dest;
    }

    function changeOwner(address _owner) onlyOwner {
        owner = _owner;
    }

    /**
     * 입금용 사용자 지갑 생성(Contract Address)
     */
    function makeWallet() onlyAdmins returns (address wallet) {
        wallet = address(new UserWallet(this));
        LogNewWallet(wallet);
    }

    function halt() onlyAdmins {
        halted = true;
    }

    function start() onlyOwner {
        halted = false;
    }

    address public defaultSweeper = address(new DefaultSweeper(this));
    mapping(address => address) sweepers;

    /**
     * 토큰에 따른 sweeper 추가
     * 토큰에 따라 표준 인터페이스가 아닐 수 있기 때문에 sweeper 변경할 수 있게 되어 있음
     */
    function addSweeper(address _token, address _sweeper) onlyOwner {
        sweepers[_token] = _sweeper;
    }

    /**
     * Sweeper(토큰 전송 컨트랙트) 가져오기
     * 특정 토큰에 따라 sweeper 지정될 수 있음
     */
    function sweeperOf(address _token) returns (address) {
        address sweeper = sweepers[_token];
        if (sweeper == 0) sweeper = defaultSweeper;
        return sweeper;
    }

    function logSweep(
        address from,
        address to,
        address token,
        uint256 amount
    ) {
        LogSweep(from, to, token, amount);
    }
}
