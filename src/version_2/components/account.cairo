/// # Account Component
#[starknet::component]
mod AccountComponent {
    use accounts_poc::version_2::components::signature_validator::ValidSignatureTrait;
    use starknet::account::Call;
    use starknet::get_caller_address;
    use starknet::get_contract_address;
    use starknet::get_tx_info;

    const TRANSACTION_VERSION: felt252 = 1;
    // 2**128 + TRANSACTION_VERSION
    const QUERY_VERSION: felt252 = 0x100000000000000000000000000000001;

    #[storage]
    struct Storage {
        Account_public_key: felt252
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        OwnerAdded: OwnerAdded,
        OwnerRemoved: OwnerRemoved
    }

    #[derive(Drop, starknet::Event)]
    struct OwnerAdded {
        new_owner_guid: felt252
    }

    #[derive(Drop, starknet::Event)]
    struct OwnerRemoved {
        removed_owner_guid: felt252
    }

    mod Errors {
        const INVALID_CALLER: felt252 = 'Account: invalid caller';
        const INVALID_SIGNATURE: felt252 = 'Account: invalid signature';
        const INVALID_TX_VERSION: felt252 = 'Account: invalid tx version';
        const UNAUTHORIZED: felt252 = 'Account: unauthorized';
    }

    #[generate_trait]
    impl InternalImpl<
        TContractState, +HasComponent<TContractState>, +Drop<TContractState>
    > of InternalTrait<TContractState> {
        fn initializer(ref self: ComponentState<TContractState>, public_key: felt252) {
            self._set_public_key(public_key);
        }

        fn assert_only_self(self: @ComponentState<TContractState>) {
            let caller = get_caller_address();
            let self = get_contract_address();
            assert(self == caller, Errors::UNAUTHORIZED);
        }

        fn execute_transaction(
            self: @ComponentState<TContractState>, mut calls: Array<Call>
        ) -> Array<Span<felt252>> {
            let sender = get_caller_address();
            assert(sender.is_zero(), Errors::INVALID_CALLER);

            let tx_info = get_tx_info().unbox();
            let version = tx_info.version;
            if version != TRANSACTION_VERSION {
                assert(version == QUERY_VERSION, Errors::INVALID_TX_VERSION);
            }

            _execute_calls(calls)
        }

        fn validate_transaction<+ValidSignatureTrait<TContractState>>(
            self: @ComponentState<TContractState>
        ) -> felt252 {
            let tx_info = get_tx_info().unbox();
            let tx_hash = tx_info.transaction_hash;
            let signature = tx_info.signature;
            assert(self._is_valid_signature(tx_hash, signature), Errors::INVALID_SIGNATURE);
            starknet::VALIDATED
        }

        fn _set_public_key(ref self: ComponentState<TContractState>, new_public_key: felt252) {
            self.Account_public_key.write(new_public_key);
            self.emit(OwnerAdded { new_owner_guid: new_public_key });
        }

        fn _is_valid_signature<impl Validator: ValidSignatureTrait<TContractState>>(
            self: @ComponentState<TContractState>, hash: felt252, signature: Span<felt252>
        ) -> bool {
            let contract = HasComponent::get_contract(self);
            let public_key = array![self.Account_public_key.read()].span();
            Validator::is_valid_signature(contract, hash, public_key, signature)
        }
    }

    fn _execute_calls(mut calls: Array<Call>) -> Array<Span<felt252>> {
        let mut res = ArrayTrait::new();
        loop {
            match calls.pop_front() {
                Option::Some(call) => {
                    let _res = _execute_single_call(call);
                    res.append(_res);
                },
                Option::None(_) => { break (); },
            };
        };
        res
    }

    fn _execute_single_call(call: Call) -> Span<felt252> {
        let Call{to, selector, calldata } = call;
        starknet::call_contract_syscall(to, selector, calldata.span()).unwrap()
    }
}
