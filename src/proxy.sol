/*
   Copyright 2016-2017 DappHub, LLC

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
*/

pragma solidity ^0.4.9;

import "ds-auth/auth.sol";
import "Ds-note/note.sol";

contract DSProxy is DSAuth, DSNote {

	function execute(bytes _code, bytes _data)
		auth
		note
		payable
		returns (bytes32 response)
	{
		uint256 codeLength = _code.length;
		uint256 dataLength = _data.length;

		assembly {
			let target := create(0, add(_code, 0x20), mload(_code))	//deploy contract
			jumpi(0x02, iszero(target))                 			//verify address of deployed contract
			//calldatacopy(pMem, _data, dataLength)       			//copy request data from calldata to memory
			let pMem := mload(0x40)                     			//load free memory pointer
			let succeeded := delegatecall(gas, target, add(_data, 0x20), mload(_data), pMem, 32) //call deployed contract
			jumpi(0x02, iszero(succeeded))              			//throw if delegatecall failed
			response := mload(pMem)                     			//set delegatecall output to response
		}
		return response;		
	}
}

contract DSProxyFactory {
	event Created(address sender, address proxy);

	mapping(address=>bool) public isProxy;

    function build() returns (DSProxy) {
        var proxy = new DSProxy();
        Created(msg.sender, proxy);
        proxy.setAuthority(msg.sender);
        isProxy[proxy] = true;
        return proxy;
    }
}