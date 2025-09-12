
/// Module: jelo_coin
module jelo_coin::jelo;


// For Move coding conventions, see
// https://docs.sui.io/concepts/sui-move-concepts/conventions



use sui::coin::{Self, TreasuryCap};
use sui::url::new_unsafe_from_bytes;
use sui::balance::{Balance};
use sui::clock::{Self, Clock};

const EInvalidAmount: u64 = 0;
const ESupplyExcided: u64 = 1;
const ETokenLocked: u64 = 2;

public struct JELO has drop {}

public struct MintCapability has key {
    id: UID,
    treasury: TreasuryCap<JELO>,
    total_minted: u64
}

public struct Locker has key, store {
    id: UID,
    unlock_date: u64,
    balance: Balance<JELO>,
}



const TOTAL_SUPPLY: u64 = 1_000_000_000_000_000_000;
const INITAL_SUPPLY: u64 = 900_000_000_000_000_000;


// const COMMUNITY_SUPPLY: u64 = 700_000_000_000_000_000;
// const CE_SUPPLY: u64 = 200_000_000_000_000_000;
// const OPERATION_SUPPLY: u64 = 100_000_000_000_000_000;


fun init(otw: JELO, ctx: &mut TxContext) {
    let (treasury, metadata) = coin::create_currency(
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
        treasury,
        total_minted: 0
    };
    mint(&mut mint_cap, INITAL_SUPPLY, ctx.sender(), ctx);
    // mint(&mut treasury, CE_SUPPLY, @jelo_ce, ctx);
    // mint(&mut treasury, OPERATION_SUPPLY, ctx.sender(), ctx);


    transfer::public_freeze_object(metadata);
    // transfer::public_freeze_object(treasury);
    transfer::transfer(mint_cap, ctx.sender());
    // transfer::public_transfer(treasury, ctx.sender());
}


public fun mint(
    mint_cap: &mut MintCapability,
    amount: u64,
    recepient: address,
    ctx: &mut TxContext
){

    let coin = mint_internal(mint_cap, amount, ctx);
    transfer::public_transfer(coin, recepient);


}


public fun mint_locked(
    mint_cap: &mut MintCapability,
    amount: u64,
    recepient: address,
    duration: u64,
    clock: &Clock,
    ctx: &mut TxContext
) {
    let coin = mint_internal(mint_cap, amount, ctx);
    let start_date = clock::timestamp_ms(clock);
    let unlock_date = start_date + duration;

    let locker = Locker{
        id: object::new(ctx),
        unlock_date,
        balance: coin::into_balance(coin)
    };


    transfer::public_transfer(locker, recepient);
}


entry fun withdraw_locked(
    locker: Locker,
    clock: &Clock,
    ctx: &mut TxContext
): u64 {

    let Locker {id, mut balance, unlock_date} = locker;
    assert!(clock.timestamp_ms() >= unlock_date, ETokenLocked);

    let locked_balance_value = balance.value();
    transfer::public_transfer(
        coin::take(&mut balance, locked_balance_value, ctx),
        ctx.sender()
    );

    balance.destroy_zero();
    object::delete(id);

    locked_balance_value
}


fun mint_internal(
    mint_cap: &mut MintCapability,
    amount: u64,
    ctx: &mut TxContext
): coin::Coin<JELO> {

    assert!(amount > 0, EInvalidAmount);
    assert!(mint_cap.total_minted + amount <= TOTAL_SUPPLY, ESupplyExcided);
    
    let treasury = &mut mint_cap.treasury;

    let coin = coin::mint(treasury, amount, ctx);

    mint_cap.total_minted = mint_cap.total_minted + amount;

    coin
}


#[test_only]
use sui::test_scenario;


#[test]
fun test_init() {
    let publisher = @0x11;

    let mut scenario = test_scenario::begin(publisher);
    {
        let otw = JELO{};
        init(otw, scenario.ctx());
    };

    scenario.next_tx(publisher);
    {
        let mint_cap = scenario.take_from_sender<MintCapability>();
        let jelo_coin = scenario.take_from_sender<coin::Coin<JELO>>();


        assert!(mint_cap.total_minted == INITAL_SUPPLY, EInvalidAmount);
        assert!(jelo_coin.balance().value() == INITAL_SUPPLY, EInvalidAmount);


        scenario.return_to_sender(jelo_coin);
        scenario.return_to_sender(mint_cap);
    };


    scenario.next_tx(publisher);
    {

        let mut mint_cap = scenario.take_from_sender<MintCapability>();


        mint(
            &mut mint_cap,
            100_000_000_000_000_000,
            scenario.ctx().sender(),
            scenario.ctx()
        );

        assert!(mint_cap.total_minted == TOTAL_SUPPLY, EInvalidAmount);
        scenario.return_to_sender(mint_cap);
    };

    scenario.end();
}