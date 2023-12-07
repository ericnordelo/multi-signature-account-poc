#[starknet::interface]
trait ValidSignatureTrait<TContractState> {
    fn is_valid_signature(
        self: @TContractState,
        msg_hash: felt252,
        verifiable_key: Span<felt252>,
        signature: Span<felt252>
    ) -> bool;
}

#[starknet::component]
mod SignatureValidatorComponent {
    use ecdsa::check_ecdsa_signature;
    use starknet::eth_signature::is_eth_signature_valid;
    use starknet::eth_signature::{Signature, EthAddress};

    #[storage]
    struct Storage {}

    impl StarknetImpl<
        TContractState, +HasComponent<TContractState>,
    > of super::ValidSignatureTrait<TContractState> {
        fn is_valid_signature(
            self: @TContractState,
            msg_hash: felt252,
            verifiable_key: Span<felt252>,
            signature: Span<felt252>
        ) -> bool {
            let public_key = verifiable_key;
            let valid_length = public_key.len() == 1 && signature.len() == 2;

            if valid_length {
                check_ecdsa_signature(
                    msg_hash, *public_key.at(0), *signature.at(0), *signature.at(1)
                )
            } else {
                false
            }
        }
    }

    impl EthereumImpl<
        TContractState, +HasComponent<TContractState>,
    > of super::ValidSignatureTrait<TContractState> {
        fn is_valid_signature(
            self: @TContractState,
            msg_hash: felt252,
            verifiable_key: Span<felt252>,
            signature: Span<felt252>
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
}
