//SPDX-License-Identifier: Unlicense
pragma solidity >=0.5.0;

import "./token/ERC20/ERC20.sol";
import "./utils/math/SafeMath.sol";

contract BUP is ERC20 {
    string public constant name = "BuildUP";
    string public constant symbol = "BUP";
    uint8 public constant decimals = 18;
    uint256 public constant initialSupply =
        10000000000 * (10**uint256(decimals));

    constructor() public {
        super._mint(msg.sender, initialSupply);
        owner = msg.sender;
    }

    //ownership
    address public owner;

    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0), "Already owner");
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

    //pausable
    event Pause();
    event Unpause();

    bool public paused = false;

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!paused, "Paused by owner");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(paused, "Not paused now");
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }

    //freezable
    event Frozen(address target);
    event Unfrozen(address target);

    mapping(address => bool) internal freezes;

    modifier whenNotFrozen() {
        require(!freezes[msg.sender], "Sender account is locked.");
        _;
    }

    function freeze(address _target) public onlyOwner {
        freezes[_target] = true;
        emit Frozen(_target);
    }

    function unfreeze(address _target) public onlyOwner {
        freezes[_target] = false;
        emit Unfrozen(_target);
    }

    function isFrozen(address _target) public view returns (bool) {
        return freezes[_target];
    }

    function transfer(address _to, uint256 _value)
        public
        whenNotFrozen
        whenNotPaused
        returns (bool)
    {
        releaseLock(msg.sender);
        return super.transfer(_to, _value);
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public whenNotPaused returns (bool) {
        require(!freezes[_from], "From account is locked.");
        releaseLock(_from);
        return super.transferFrom(_from, _to, _value);
    }

    //mintable
    event Mint(address indexed to, uint256 amount);

    function mint(address _to, uint256 _amount)
        public
        onlyOwner
        returns (bool)
    {
        super._mint(_to, _amount);
        emit Mint(_to, _amount);
        return true;
    }

    //burnable
    event Burn(address indexed burner, uint256 value);

    function burn(address _who, uint256 _value) public onlyOwner {
        require(_value <= super.balanceOf(_who), "Balance is too small.");

        _burn(_who, _value);
        emit Burn(_who, _value);
    }

    //lockable
    struct LockInfo {
        uint256 releaseTime;
        uint256 balance;
    }
    mapping(address => LockInfo[]) internal lockInfo;

    event Lock(address indexed holder, uint256 value, uint256 releaseTime);
    event Unlock(address indexed holder, uint256 value);

    function balanceOf(address _holder) public view returns (uint256 balance) {
        uint256 lockedBalance = 0;
        for (uint256 i = 0; i < lockInfo[_holder].length; i++) {
            lockedBalance = lockedBalance.add(lockInfo[_holder][i].balance);
        }
        return super.balanceOf(_holder).add(lockedBalance);
    }

    function releaseLock(address _holder) internal {
        for (uint256 i = 0; i < lockInfo[_holder].length; i++) {
            if (lockInfo[_holder][i].releaseTime <= now) {
                _balances[_holder] = _balances[_holder].add(
                    lockInfo[_holder][i].balance
                );
                emit Unlock(_holder, lockInfo[_holder][i].balance);
                lockInfo[_holder][i].balance = 0;

                if (i != lockInfo[_holder].length - 1) {
                    lockInfo[_holder][i] = lockInfo[_holder][
                        lockInfo[_holder].length - 1
                    ];
                    i--;
                }
                lockInfo[_holder].length--;
            }
        }
    }

    function lockCount(address _holder) public view returns (uint256) {
        return lockInfo[_holder].length;
    }

    function lockState(address _holder, uint256 _idx)
        public
        view
        returns (uint256, uint256)
    {
        return (
            lockInfo[_holder][_idx].releaseTime,
            lockInfo[_holder][_idx].balance
        );
    }

    function lock(
        address _holder,
        uint256 _amount,
        uint256 _releaseTime
    ) public onlyOwner {
        require(super.balanceOf(_holder) >= _amount, "Balance is too small.");
        _balances[_holder] = _balances[_holder].sub(_amount);
        lockInfo[_holder].push(LockInfo(_releaseTime, _amount));
        emit Lock(_holder, _amount, _releaseTime);
    }

    function lockAfter(
        address _holder,
        uint256 _amount,
        uint256 _afterTime
    ) public onlyOwner {
        require(super.balanceOf(_holder) >= _amount, "Balance is too small.");
        _balances[_holder] = _balances[_holder].sub(_amount);
        lockInfo[_holder].push(LockInfo(now + _afterTime, _amount));
        emit Lock(_holder, _amount, now + _afterTime);
    }

    function unlock(address _holder, uint256 i) public onlyOwner {
        require(i < lockInfo[_holder].length, "No lock information.");

        _balances[_holder] = _balances[_holder].add(
            lockInfo[_holder][i].balance
        );
        emit Unlock(_holder, lockInfo[_holder][i].balance);
        lockInfo[_holder][i].balance = 0;

        if (i != lockInfo[_holder].length - 1) {
            lockInfo[_holder][i] = lockInfo[_holder][
                lockInfo[_holder].length - 1
            ];
        }
        lockInfo[_holder].length--;
    }

    function transferWithLock(
        address _to,
        uint256 _value,
        uint256 _releaseTime
    ) public onlyOwner returns (bool) {
        require(_to != address(0), "wrong address");
        require(_value <= super.balanceOf(owner), "Not enough balance");

        _balances[owner] = _balances[owner].sub(_value);
        lockInfo[_to].push(LockInfo(_releaseTime, _value));
        emit Transfer(owner, _to, _value);
        emit Lock(_to, _value, _releaseTime);

        return true;
    }

    function transferWithLockAfter(
        address _to,
        uint256 _value,
        uint256 _afterTime
    ) public onlyOwner returns (bool) {
        require(_to != address(0), "wrong address");
        require(_value <= super.balanceOf(owner), "Not enough balance");

        _balances[owner] = _balances[owner].sub(_value);
        lockInfo[_to].push(LockInfo(now + _afterTime, _value));
        emit Transfer(owner, _to, _value);
        emit Lock(_to, _value, now + _afterTime);

        return true;
    }

    function currentTime() public view returns (uint256) {
        return now;
    }

    function afterTime(uint256 _value) public view returns (uint256) {
        return now + _value;
    }
}
