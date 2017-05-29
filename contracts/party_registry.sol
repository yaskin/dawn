pragma solidity ^0.4.12;

/// @title Registry of contractual parties in the system. The registry allow for the validation of parties.
contract PartyRegistry {

	address private owner;					// Registry owner

	enum State {
		PENDING,							// Pending state of a PartyContract.
		ACTIVE,								// Active state of a PartyContract.
		INACTIVE,							// Inactive state of a PartyContract.
		REJECTED,							// Rejected state of a PartyContract.
		CANCELLED,							// Cancelled state of a PartyContract.
		LOCKED								// Locked state of a PartyContract.
	}

	/// @dev Party contract composed of the hash of contract bytecode.
	struct PartyContract {
		bytes32 hash;						// Hash of contract bytecode
		address party;						// Account party that submitted the address
		State state;						// State of the contract
	}


	/// @dev General Constructor.
	function PartyRegistry() {
		owner = msg.sender;
	}


	/// @dev Mapping for contract registry.
	mapping(bytes32 => PartyContract) public partycontracts;


	/**
	 * Check Identity is valid using modifier.
	 *
	 * This will also serve as protection against forks, because at the time the chain forks,
	 * we can kill the registry, which will then 'invalidate' the identities that are stored
	 * on the old chain.
	 *
	 * @param identity Registry owner's address
	 * @param registry Registry owner's address
	 * @return bool True if successful, false otherwise
	 */
	modifier checkIdentity(address identity, address registry) return (bool) {
		if (registry.isValid(identity) != 1) {
			throw;
		}
	}


	/**
	 * Ensure a permission where only the registry owner can initiate a change.
	 * Contract owner can interact as an anonymous third party by simply using
	 * another public key address.
	 *
	 * @param _account Registry owner's address
	 * @return _account Registry owner's address
	 */
	modifier onlyOwner(address _account) {
		if (msg.sender != _account) {
			throw;
			_;
		}
	}


	/**
	 *
	 */
	modifier inState(State _state) {
		require(state == _state);
		_;
	}


	/**
	 * Only the registry owner can approve a party contract.
	 *
	 * @param contract Hash of the contract
	 * @param owner Registry owner's address
	 * @return bool True if successful, false otherwise
	 */
	function approve(bytes32 contract) onlyOwner(owner) returns(bool) {
		var partycontract = partycontracts[contract];
		if (partycontract != null) {
			partycontract.state = State.ACTIVE;
			return true;
		}
		return false;
	}


	/**
	 * Only the registry owner and original submitter can delete a contract.
	 * A contract in the rejected list cannot be removed.
	 *
	 * @param contract
	 * @return bool True if successful, false otherwise
	 */
	function delete(bytes32 contract) returns(bool) {
		var partycontract = partycontracts[contract];
		if (partycontract.state != State.REJECTED
				&& partycontract.submitter == msg.sender
				&& msg.sender == owner) {
			delete partycontracts[contract];
			return true;
		}
		else {
			throw;
		}
	}


	/**
	* This is the public registry function that contracts should use to check
	* whether a contract is valid. It's defined as a function, rather than .call
	* so that the registry owner can choose to charge based on their reputation
	* of managing good contracts in a registry.
	*
	* Using a function rather than a call also allows for better management of
	* dependencies when a chain forks, as the registry owner can choose to kill
	* the registry on the wrong fork to stop this function executing.
	 *
	 * @param contract
	 * @return bool True if successful, false otherwise
	*/
	function isValid(bytes32 contract) returns(bool) {
		if (partycontracts[contract].state == State.ACTIVE) {
			return true;
		}
		else if (partycontracts[contract].state == State.REJECTED) {
			throw;
		}
		else {
			return false;
		}
	}


	/**
	 * Kill function to end the registry.
	 */
	function kill() onlyBy(owner) returns(uint) {
		selfdestruct(owner);
	}


	/**
	* Only the registry owner (ideally multi-sig) can reject a contract.
	*/
	function reject(bytes32 contract) onlyOwner(owner) returns(bool) {
		var partycontract = partycontracts[contract];
		partycontract.state = State.REJECTED;
		return true;
	}


	/**
	 * Anyone can submit a party contract for acceptance into the registry.
	 *
	 * @param contract
	 * @return bool True if successful, false otherwise
	 */
	function submit(bytes32 contract) returns(bool) {
		var partycontract = partycontracts[contract];
		partycontract.hash = contract;
		partycontract.party = msg.sender;
		partycontract.state = State.PENDING;
		return true;
	}
}
