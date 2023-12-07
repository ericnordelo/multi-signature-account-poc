/// # Ethereum Account Preset
#[starknet::contract]
mod Account {
    use accounts_poc::version_3::components::AccountComponent;
    use starknet::account::Call;
    use starknet::get_caller_address;
    use starknet::get_contract_address;
    use starknet::get_tx_info;

    component!(path: AccountComponent, storage: account, event: AccountEvent);

    // Starknet account
    #[abi(embed_v0)]
    impl SRC6Impl = AccountComponent::SRC6StarknetImpl<ContractState>;
    impl AccountInternalImpl = AccountComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        account: AccountComponent::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        AccountEvent: AccountComponent::Event,
    }

    #[constructor]
    fn constructor(ref self: ContractState, public_key: felt252) {
        self.account.initializer(public_key);
    }
}
