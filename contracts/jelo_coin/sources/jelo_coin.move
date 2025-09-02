
/// Module: jelo_coin
module jelo_coin::jelo;


// For Move coding conventions, see
// https://docs.sui.io/concepts/sui-move-concepts/conventions



use sui::coin::{Self, TreasuryCap};
use sui::url::new_unsafe_from_bytes;


const EInvalidAmount: u64 = 0;
const ESupplyExcided: u64 = 1;

public struct JELO has drop {}
public struct MintCapability has key {
    id: UID,
    total_minted: u64
}



const TOTAL_SUPPLY: u64 = 1_000_000_000_000_000_000;
const INITAL_SUPPLY: u64 = 100_000_000_000_000_000;


// const COMMUNITY_SUPPLY: u64 = 700_000_000_000_000_000;
// const CE_SUPPLY: u64 = 200_000_000_000_000_000;
// const OPERATION_SUPPLY: u64 = 100_000_000_000_000_000;


fun init(otw: JELO, ctx: &mut TxContext) {
    let (mut treasury, metadata) = coin::create_currency(
        otw,
        9,
        b"JELO",
        b"JELO",
        b"Meet Jelo the cutest jellyfish meme coin floating through blockchain ocean, dive into a world of fun community, and rewards",
        option::some(new_unsafe_from_bytes(b"https://singforamoment.sirv.com/jelo_coin.jpg")),
        ctx
    );


    let mut mint_cap: MintCapability = MintCapability {
        id:object::new(ctx),
        total_minted: 0
    };
    mint(&mut treasury, &mut mint_cap, INITAL_SUPPLY, ctx.sender(), ctx);
    // mint(&mut treasury, CE_SUPPLY, @jelo_ce, ctx);
    // mint(&mut treasury, OPERATION_SUPPLY, ctx.sender(), ctx);


    transfer::public_freeze_object(metadata);
    // transfer::public_freeze_object(treasury);
    transfer::public_transfer(treasury, ctx.sender());
    transfer::transfer(mint_cap, ctx.sender());
    // transfer::public_transfer(treasury, ctx.sender());
}


public fun mint(
    treasury_cap: &mut TreasuryCap<JELO>,
    mint_cap: &mut MintCapability,
    amount: u64,
    recepient: address,
    ctx: &mut TxContext
){

    assert!(amount > 0, EInvalidAmount);
    assert!(mint_cap.total_minted + amount <= TOTAL_SUPPLY, ESupplyExcided);


    let coin = coin::mint(treasury_cap, amount, ctx);
    transfer::public_transfer(coin, recepient);

    mint_cap.total_minted = mint_cap.total_minted + amount;
}