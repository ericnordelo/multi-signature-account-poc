/// # Ethereum Account Preset
#[starknet::contract]
mod Account {
    use accounts_poc::version_2::components::{AccountComponent, SignatureValidatorComponent};
    use starknet::account::Call;
    use starknet::get_caller_address;
    use starknet::get_contract_address;
    use starknet::get_tx_info;

    component!(path: AccountComponent, storage: account, event: AccountEvent);
    component!(
        path: SignatureValidatorComponent,
        storage: signature_validator,
        event: SignatureValidatorEvent
    );

    // Account
    impl AccountInternalImpl = AccountComponent::InternalImpl<ContractState>;

    // SignatureValidator for Starknet account
    impl ValidatorImpl = SignatureValidatorComponent::StarknetImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        account: AccountComponent::Storage,
        #[substorage(v0)]
        signature_validator: SignatureValidatorComponent::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        AccountEvent: AccountComponent::Event,
        #[flat]
        SignatureValidatorEvent: SignatureValidatorComponent::Event,
    }

    #[constructor]
    fn constructor(ref self: ContractState, public_key: felt252) {
        self.account.initializer(public_key);
    }

    #[generate_trait]
    #[external(v0)]
    impl ExternalImpl of ExternalTrait {
        fn __execute__(self: @ContractState, mut calls: Array<Call>) -> Array<Span<felt252>> {
            self.account.execute_transaction(calls)
        }

        fn __validate__(self: @ContractState, mut calls: Array<Call>) -> felt252 {
            self.account.validate_transaction()
        }

        /// Verifies that the given signature is valid for the given hash.
        fn is_valid_signature(
            self: @ContractState, hash: felt252, signature: Array<felt252>
        ) -> felt252 {
            if self.account._is_valid_signature(hash, signature.span()) {
                starknet::VALIDATED
            } else {
                0
            }
        }
    }
}
