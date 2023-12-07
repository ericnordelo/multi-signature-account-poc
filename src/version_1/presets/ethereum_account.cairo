/// # Ethereum Account Preset
#[starknet::contract]
mod Account {
    use accounts_poc::version_1::components::{AccountComponent, SignatureValidatorComponent};

    component!(path: AccountComponent, storage: account, event: AccountEvent);
    component!(
        path: SignatureValidatorComponent,
        storage: signature_validator,
        event: SignatureValidatorEvent
    );

    // Account
    #[abi(embed_v0)]
    impl SRC6Impl = AccountComponent::SRC6Impl<ContractState>;
    impl AccountInternalImpl = AccountComponent::InternalImpl<ContractState>;

    // SignatureValidator for Ethereum account
    impl ValidatorImpl = SignatureValidatorComponent::EthereumImpl<ContractState>;

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
}
