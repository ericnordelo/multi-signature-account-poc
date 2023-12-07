/// # Ethereum Account Preset
#[starknet::contract]
mod Account {
    use accounts_poc::version_2::components::{AccountComponent};
    use accounts_poc::version_2::components::account::ValidSignatureTrait;

    use ecdsa::check_ecdsa_signature;
    use starknet::eth_signature::is_eth_signature_valid;
    use starknet::eth_signature::{Signature, EthAddress};

    component!(path: AccountComponent, storage: account, event: AccountEvent);


    impl EthereumImpl of ValidSignatureTrait {
        fn is_valid_signature(
            msg_hash: felt252, verifiable_key: Span<felt252>, signature: Span<felt252>
        ) -> bool {
            let mut verifiable_key = verifiable_key;
            let mut signature = signature;

            let eth_address: EthAddress = Serde::deserialize(ref verifiable_key).unwrap();
            let signature: Signature = Serde::deserialize(ref signature).unwrap();

            match is_eth_signature_valid(msg_hash.into(), signature, eth_address) {
                Result::Ok(()) => true,
                Result::Err(err) => false,
            }
        }
    }
    // Account
    #[abi(embed_v0)]
    impl SRC6Impl = AccountComponent::SRC6Impl<ContractState>;
    impl AccountInternalImpl = AccountComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        account: AccountComponent::Storage
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        AccountEvent: AccountComponent::Event
    }

    #[constructor]
    fn constructor(ref self: ContractState, public_key: felt252) {
        self.account.initializer(public_key);
    }
}
