use aiken/collection/dict
use aiken/collection/list
use cardano/address.{Script}
use cardano/assets.{PolicyId}
use cardano/transaction.{OutputReference, Transaction}

// The redeemer type for our minting policy
pub type Action {
  CheckMint
  CheckBurn
}

// Ticket (Gift Card) minting policy
validator ticket(token_name: ByteArray, utxo_ref: OutputReference) {
  // Mint handler: creates or burns the NFT
  mint(redeemer: Action, policy_id: PolicyId, transaction: Transaction) {
    let Transaction { inputs, mint, .. } = transaction

    // Expect exactly one asset entry under this policy
    expect [Pair(asset_name, amount)] =
      mint
        |> assets.tokens(policy_id)
        |> dict.to_pairs()

    when redeemer is {
      CheckMint -> {
        // Ensure UTXO (the seed) is consumed to make minting one-shot
        expect Some(_input) =
          list.find(inputs, fn(input) { input.output_reference == utxo_ref })

        // Mint exactly 1 NFT
        amount == 1 && asset_name == token_name
      }
      CheckBurn ->
        // Ensure the NFT is burned
        amount == -1 && asset_name == token_name
    }
  }

  else(_) {
    fail
  }
}
