// Overmind's quest library: https://docs.overmind.xyz/quests/quest-library/slice-the-jpeg
module overmind::slice_the_jpeg {

    //==============================================================================================
    // Imports 
    //==============================================================================================

    use aptos_framework::object::{Self, Object};            // https://github.com/aptos-labs/aptos-core/blob/main/aptos-move/framework/aptos-framework/doc/object.md#module-0x1object
    use aptos_framework::account;                           // https://github.com/aptos-labs/aptos-core/blob/main/aptos-move/framework/aptos-framework/doc/account.md
    use aptos_token_objects::collection;                    // https://github.com/aptos-labs/aptos-core/blob/main/aptos-move/framework/aptos-token-objects/doc/collection.md#module-0x4collection
    use std::string::{Self, String};                        // https://github.com/aptos-labs/aptos-core/blob/main/aptos-move/framework/move-stdlib/doc/string.md#module-0x1string
    use std::option;                                        // https://github.com/aptos-labs/aptos-core/blob/main/aptos-move/framework/move-stdlib/doc/option.md#module-0x1option
    use aptos_framework::coin;                              // https://github.com/aptos-labs/aptos-core/blob/main/aptos-move/framework/aptos-framework/doc/coin.md#module-0x1coin
    use std::signer;                                        // https://github.com/aptos-labs/aptos-core/blob/main/aptos-move/framework/move-stdlib/doc/signer.md#module-0x1signer
    use aptos_framework::aptos_coin::AptosCoin;             // https://github.com/aptos-labs/aptos-core/blob/main/aptos-move/framework/aptos-framework/doc/aptos_coin.md#module-0x1aptos_coin
    use aptos_token_objects::token;                         // https://github.com/aptos-labs/aptos-core/blob/main/aptos-move/framework/aptos-token-objects/doc/token.md#module-0x4token
    use aptos_framework::primary_fungible_store;            // https://github.com/aptos-labs/aptos-core/blob/main/aptos-move/framework/aptos-framework/doc/primary_fungible_store.md#module-0x1primary_fungible_store
    use aptos_framework::fungible_asset::{Self, Metadata};  // https://github.com/aptos-labs/aptos-core/blob/3d281ad455bd5881c41ae86cd7982b1fa2092cbf/aptos-move/framework/aptos-framework/doc/fungible_asset.md#module-0x1fungible_asset
    use aptos_token_objects::property_map;                  // https://github.com/aptos-labs/aptos-core/blob/main/aptos-move/framework/aptos-token-objects/doc/property_map.md#module-0x4property_map
    use aptos_framework::event::{Self, EventHandle};        // https://github.com/aptos-labs/aptos-core/blob/main/aptos-move/framework/aptos-framework/doc/event.md#module-0x1event

    //==============================================================================================
    // Constants
    //==============================================================================================

    const SEED: vector<u8> = b"slice";

    const SPLIT_COLLECTION_DESCRIPTION: vector<u8> = b"split collection description";
    const SPLIT_COLLECTION_NAME: vector<u8> = b"split collecton name";
    const SPLIT_COLLECTION_URI: vector<u8> = b"split collection uri";

    const PROPERTY_NAME_CALL_PRICE: vector<u8> = b"Call price";
    const PROPERTY_NAME_CALL_THRESHOLD: vector<u8> = b"Call threshold";
    const PROPERTY_NAME_MAX_SUPPLY: vector<u8> = b"Max supply";
    const PROPERTY_NAME_NFT_ADDRESS: vector<u8> = b"NFT address";
    const PROPERTY_NAME_NFT_TOKEN_NAME: vector<u8> = b"NFT token name";
    const PROPERTY_NAME_NFT_COLLECTION_NAME: vector<u8> = b"NFT collection name";
    const PROPERTY_NAME_NFT_CREATOR_ADDRESS: vector<u8> = b"NFT creator address";

    //==============================================================================================
    // Error codes 
    //==============================================================================================

    const EAccountDoesNotOwnNft: u64 = 1;
    const ETokenSupplyIsZero: u64 = 2;
    const EThresholdAmountIsGreaterThanTokenSupply: u64 = 3;
    const EThresholdAmountIsNotGreaterThanHalfOfSupply: u64 = 4;
    const ESplitTokenAlreadyExists: u64 = 5;
    const ETokenBalanceIsNotEqualToTokenSupply: u64 = 6;
    const ENftIsNotOwnedByAccount: u64 = 7;
    const ENftIsOwnedByAccount: u64 = 8;
    const ESplitTokenBalanceIsLessThanCallThreshold: u64 = 9;
    const EAptosCoinBalanceIsLessThanCallPayment: u64 = 10;
    const ESplitTokenBalanceIsZero: u64 = 11;

    //==============================================================================================
    // Functional structs
    //==============================================================================================

    struct State has key {
        signer_capability: account::SignerCapability,
        collection_address: address,
        split_events: EventHandle<SplitEvent>,
        redeem_events: EventHandle<RedeemEvent>,
        call_events: EventHandle<CallEvent>,
        exchange_events: EventHandle<ExchangeEvent>
    }

    struct SplitToken has key {
        property_mutator_ref: property_map::MutatorRef,
        fungible_asset_mint_ref: fungible_asset::MintRef,
        fungible_asset_burn_ref: fungible_asset::BurnRef,
    }

    //==============================================================================================
    // Event structs
    //==============================================================================================

    struct SplitEvent has store, drop {
        splitter_address: address,
        nft_address: address, 
        split_token_address: address, 
        split_token_supply: u64,
        split_token_call_threshold: u64, 
        split_token_call_price: u64
    }

    struct RedeemEvent has store, drop {
        redeemer_address: address, 
        nft_address: address
    }

    struct CallEvent has store, drop {
        caller_address: address, 
        nft_address: address, 
        caller_split_token_amount: u64,
        aptos_call_payment_amount: u64
    }

    struct ExchangeEvent has store, drop {
        exchanger_address: address, 
        nft_address: address, 
        split_token_exchange_amount: u64, 
        aptos_coin_exchange_payment: u64
    }

    //==============================================================================================
    // Functions
    //==============================================================================================

    fun init_module(account: &signer) {
        
        let account_address = signer::address_of(account);

        // TODO: Create the module's resource account using the account signer and the SEED provided
        //       above. 
        //
        let (account_resource_signer, signer_capability) = 
                    account::create_resource_account(account, SEED);

        // NOTE: Make sure to use the SEED constant or the tests won't pass
        

        // TODO: Register the resource account with the AptosCoin coin module. 

        // TODO: Create the v2 token collection that will hold all of the fungible split tokens
        // 
        // USE: Use the create_split_collection function below

        // TODO: Create a new State object and send it to account

    }

    public entry fun split<NFT: key >(
        nf_token_owner_signer: &signer, 
        nf_token_address: address, 
        split_token_name: String,
        split_token_symbol: String,
        split_token_description: String,
        split_token_supply: u64,
        split_token_call_threshold: u64,
        split_token_call_price: u64,
        split_token_icon_uri: String,
        split_token_project_uri: String
    ) acquires State, SplitToken {

        // TODO: Ensure that the nf_token_owner_signer owns the provided NFT
        // 
        // USE: Use the check_if_account_owns_nft function below

        // TODO: Ensure that the provided split_token_supply is above zero
        // 
        // USE: Use the check_if_new_supply_above_zero function below

        // TODO: Ensure the split_token_call_threshold is valid with the provided split_token_supply
        // 
        // USE: Use the check_if_valid_call_threshold_amount function below

        // TODO: Ensure that the fungible split token about to be created does not already exist
        // 
        // USE: Use the check_if_split_token_does_not_exist function below
        // 
        // HINT: Pre-generate the new split token address using the creator address, 
        //       collection name, and new token name and check that address

        // TODO: Transfer the NFT to the module's resource account

        // TODO: Create the new fungible split token
        // 
        // USE: Use the create_split_token_as_fungible_token function below 

        // TODO: Mint the total supply of the new split tokens to the NFT owner
        // 
        // USE: Use the mint_internal function below

        // TODO: Emit a new SplitEvent 

    }

    public entry fun redeem<NFT: key>(
        coin_owner: &signer,
        split_token_address: address
    ) acquires State, SplitToken {

        // TODO: Ensure the NFT associated with the received split tokens is still owned by the 
        //       module's resource account
        // 
        // USE: Use the check_if_nf_token_is_owned_by_account function below

        // TODO: Ensure the coin owner's split token balance is equal to the entire supply of tokens
        // 
        // USE: Use the check_if_split_token_balance_is_equal_to_supply function below
        // 
        // HINT: Retrieve the split token supply from the split token's property_map

        // TODO: Burn all of the received split tokens
        // 
        // USE: Use the burn_internal function below

        // TODO: Transfer the associated NFT to the coin owner
        // 
        // HINT: Retreive the associated NFT address from the split token's property_map

        // TODO: Emit a new Redeem Event

    }

    public entry fun call<NFT: key>(
        coin_owner: &signer,
        split_token_address: address
    ) acquires State, SplitToken {

        // TODO: Ensure the NFT associated with the received split tokens is still owned by the 
        //       module's resource account
        // 
        // USE: Use the check_if_nf_token_is_owned_by_account function below

        // TODO: Ensure the coin owner's split token balance is equal to or above the split token's 
        //       call threshold
        // 
        // USE: Use the check_if_split_token_balance_is_equal_to_or_greater_than_call_threshold 
        //      function below
 
        // TODO: Ensure the coin owner's aptos coin balance is equal to or greater than the call payment
        // 
        // USE: Use the check_if_aptos_coin_balance_is_equal_to_or_greater_than_call_payment 
        //      function below

        // TODO: Transfer the correct amount of AptosCoin from the coin owner to the module's
        //       resource account

        // TODO: Burn the coin owners provide split tokens
        // 
        // USE: Use the burn_internal function below

        // TODO: Transfer the associated NFT to the coin owner

        // TODO: Emit a new CallEvent 
        
    }

    public entry fun exchange_split_tokens_for_call_payment<NFT: key >(
        coin_owner: &signer,
        split_token_address: address
    ) acquires State, SplitToken {

        // TODO: Ensure the NFT associated with the received split tokens is not still owned by the 
        //       module's resource account
        // 
        // USE: Use the check_if_nf_token_is_not_owned_by_account function below
 
        // TODO: Ensure the coin owner's split token balance is above zero
        // 
        // USE: Use the check_if_split_balance_is_above_zero function below

        // TODO: Transfer the correct amount of AptosCoin from the coin owner to the module's 
        //       resource account

        // TODO: Burn the coin owner's provided split tokens
        // 
        // USE: Use the burn_internal function below

        // TODO: Emit a new ExchangeEvent

    }

    //==============================================================================================
    // Helper functions
    //==============================================================================================

    fun create_split_collection(creator: &signer): address {
      
        // TODO: Create an new token collection with an unlimited token supply
        // 
        // NOTE: Use the provided constants for collection decription, name, and uri

        // TODO: Return the address of the newly creted token collection

    }

    fun create_split_token_as_fungible_token(
        creator: &signer,
        description: String,
        name: String,
        uri: String,
        fungible_asset_name: String,
        fungible_asset_symbol: String,
        icon_uri: String,
        project_uri: String,
        call_price: u64,
        call_threshold: u64,
        max_supply: u64,
        nft_address: address,
        nft_creator_address: address,
        nft_collection_name: String,
        nft_token_name: String
    ) {

        // TODO: Create a new named token in the split token collection

        // TODO: Generates the object signer and the refs. The object signer is used to publish a resource
        // (e.g., RestorationValue) under the token object address. The refs are used to manage the token.

        // TODO: Create the token's property_map with the following properties: 
        //       - nft address
        //       - call price
        //       - call threshold
        //       - max supply
        //       - nft token name
        //       - nft collection name
        //       - nft creator address
        // 
        // USE: property_map::prepare_input, property_map::init, & property_map::add_typed
        //
        // NOTE: Make sure to use the provided property keys to ensure the tests pass

        // TODO: Turn this new token into a fungible token
        // 
        // USE: primary_fungible_store::create_primary_store_enabled_fungible_asset
        
        // TODO: Create the SplitToken object with the required token info and send it to the new
        //       token object
    
    }

    
    public fun split_balance(account: address, split_token: Object<SplitToken>): u64 {
        // TODO: Fetch and return the balance of the provided fungible split token of the account
        //
        // HINT: https://aptos.dev/standards/aptos-token-v2/#fungible-token
        
    }

    fun mint_internal(split_token_object: Object<SplitToken>, receiver: address, amount: u64) acquires SplitToken {
        // TODO: Mint amount of the provided split token object and send it to the receiver address
        //
        // HINT: https://aptos.dev/standards/aptos-token-v2/#fungible-token
        
    }

    fun burn_internal(owner: &signer, split_token_object: Object<SplitToken>, amount: u64) acquires SplitToken {
        // TODO: Burn amount of split tokens from the provided split token object
        //
        // HINT: https://aptos.dev/standards/aptos-token-v2/#fungible-token
        
    }

    //==============================================================================================
    // Validation functions
    //==============================================================================================

    // HINT: Throw the EAccountDoesNotOwnNft code if check fails
    inline fun check_if_account_owns_nft<NFT: key>(account_address: address, nf_token_object: Object<NFT>) {
       
    }

    // HINT: Throw the ETokenSupplyIsZero code if check fails
    inline fun check_if_new_supply_above_zero(token_supply: u64) {
        
    }

    // HINT: Throw the EThresholdAmountIsGreaterThanTokenSupply code if the threshold amount is not 
    //       greater than the token supply and throw EThresholdAmountIsNotGreaterThanHalfOfSupply 
    //       if the threshold amount is not greter than half of the token supply
    inline fun check_if_valid_call_threshold_amount(threshold_amount: u64, token_supply: u64) {
        
    }

    // HINT: Throw the ESplitTokenAlreadyExists code if check fails
    inline fun check_if_split_token_does_not_exist(split_token_address: address) {
        
    }

    // HINT: Throw the ETokenBalanceIsNotEqualToTokenSupply code if check fails
    inline fun check_if_split_token_balance_is_equal_to_supply(token_balance: u64, token_supply: u64) {
        
    }

    // HINT: Throw the ENftIsNotOwnedByAccount code if check fails
    inline fun check_if_nf_token_is_owned_by_account<NFT: key>(nf_token_address: address, account_address: address) {
       
    }

    // HINT: Throw the ENftIsOwnedByAccount code if check fails
    inline fun check_if_nf_token_is_not_owned_by_account<NFT: key>(nf_token_address: address, account_address: address) {
        
    }

    // HINT: Throw the ESplitTokenBalanceIsLessThanCallThreshold code if check fails
    inline fun check_if_split_token_balance_is_equal_to_or_greater_than_call_threshold(split_token_balance: u64, call_threshold: u64) {
        
    }

    // HINT: Throw the EAptosCoinBalanceIsLessThanCallPayment code if check fails
    inline fun check_if_aptos_coin_balance_is_equal_to_or_greater_than_call_payment(aptos_coin_balance: u64, call_payment: u64) {
        
    }

    // HINT: Throw the ESplitTokenBalanceIsZero code if check fails
    inline fun check_if_split_balance_is_above_zero(split_token_balance: u64) {
        
    }

    //================================================================================================
    // Tests -- DO NOT edit anything below
    //================================================================================================

    #[test_only]
    use aptos_token_objects::aptos_token;                   // https://github.com/aptos-labs/aptos-core/blob/main/aptos-move/framework/aptos-token-objects/doc/aptos_token.md#module-0x4aptos_token
    #[test_only]
    use aptos_framework::aptos_coin;
    #[test_only]
    use aptos_token_objects::royalty;                       // https://github.com/aptos-labs/aptos-core/blob/main/aptos-move/framework/aptos-token-objects/doc/royalty.md#module-0x4royalty

    #[test_only]
    const EWrongNumberOfEventsEmitted: u64 = 99;

    #[test_only]
    struct TestToken1 has key {}

    #[test_only]
    struct TestToken2 has key {}

    #[test(creator = @overmind)]
    fun test_init_module_success(
        creator: &signer
    ) acquires State {

        let creator_address = signer::address_of(creator);
        account::create_account_for_test(creator_address);

        init_module(creator);

        assert!(exists<State>(creator_address), 0);

        let state = borrow_global<State>(creator_address);

        let resource_account_address = account::get_signer_capability_address(&state.signer_capability);

        let collection_address = state.collection_address;
        let collection_object = object::address_to_object<collection::Collection>(collection_address);
        let expected_collection_address = collection::create_collection_address(
            &resource_account_address,
            &string::utf8(SPLIT_COLLECTION_NAME)
        );
        // Verify collection is correctly setup
        assert!(collection_address == expected_collection_address, 0);
        assert!(
            collection::creator<collection::Collection>(collection_object) == resource_account_address,
            0
        );
        assert!(
            collection::name<collection::Collection>(collection_object) == string::utf8(SPLIT_COLLECTION_NAME),
            0
        );
        assert!(
            collection::description<collection::Collection>(collection_object) == string::utf8(SPLIT_COLLECTION_DESCRIPTION),
            0
        );
        assert!(
            collection::uri<collection::Collection>(collection_object) == string::utf8(SPLIT_COLLECTION_URI),
            0
        );

        assert!(account::exists_at(resource_account_address) == true, 0);
        assert!(coin::is_account_registered<AptosCoin>(resource_account_address), 0);

    }

    #[test(creator = @overmind, account = @0xA)]
    fun test_split_success_1_NFTs(
        creator: &signer,
        account: &signer
    ) acquires State, SplitToken {

        let creator_address = signer::address_of(creator);
        let account_address = signer::address_of(account);
        let receiver_address = @0xB;
        account::create_account_for_test(creator_address);
        account::create_account_for_test(account_address);
        account::create_account_for_test(receiver_address);

        init_module(creator);

        let nf_token_collection_name = b"collection1";
        let nf_token_name = b"token1";

        create_nft_collection(account, nf_token_collection_name);
        let nf_token_object = mint_nft_1(account, nf_token_collection_name, nf_token_name);
        let nf_token_address = object::object_address<TestToken1>(&nf_token_object);

        let expected_split_token_name = b"split token";
        let expected_split_token_symbol = b"SPLIT";
        let expected_split_token_description = b"split token desc";
        let expected_split_token_call_threshold = 900_0000_0000;
        let expected_split_token_call_price = 1_0000_0000;
        let expected_split_token_supply = 1000_0000_0000;
        let expected_split_token_icon_uri = b"icon uri";
        let expected_split_token_project_uri = b"project uri";
        split<TestToken1>(
            account,
            nf_token_address,
            string::utf8(expected_split_token_name),
            string::utf8(expected_split_token_symbol),
            string::utf8(expected_split_token_description),
            expected_split_token_supply,
            expected_split_token_call_threshold,
            expected_split_token_call_price,
            string::utf8(expected_split_token_icon_uri),
            string::utf8(expected_split_token_project_uri)
        );

        let state = borrow_global<State>(creator_address);
        let resource_account_signer_cap_ref = &state.signer_capability;
        let resource_account_address = account::get_signer_capability_address(resource_account_signer_cap_ref);

        let split_token_address = split_token_address(expected_split_token_name);
        let expected_split_token_address = token::create_token_address(
            &resource_account_address,
            &string::utf8(SPLIT_COLLECTION_NAME),
            &string::utf8(expected_split_token_name)
        );
        let split_token_object = object::address_to_object<SplitToken>(split_token_address(expected_split_token_name));
        assert!(split_token_address == expected_split_token_address, 0);
        assert!(
            token::creator<SplitToken>(split_token_object) == resource_account_address,
            0
        );
        assert!(
            token::collection_name<SplitToken>(split_token_object) == string::utf8(SPLIT_COLLECTION_NAME),
            0
        );
        assert!(
            token::name<SplitToken>(split_token_object) == string::utf8(expected_split_token_name),
            0
        );
        assert!(
            token::description<SplitToken>(split_token_object) == string::utf8(expected_split_token_description),
            0
        );
        assert!(
            token::uri<SplitToken>(split_token_object) == string::utf8(expected_split_token_project_uri),
            0
        );
        assert!(
            option::is_none<royalty::Royalty>(&token::royalty<SplitToken>(split_token_object)) == true,
            0
        );
        assert!(
            property_map::read_address<SplitToken>(&split_token_object, &string::utf8(PROPERTY_NAME_NFT_ADDRESS)) == nf_token_address,
            0
        );
        assert!(
            property_map::read_u64<SplitToken>(&split_token_object, &string::utf8(PROPERTY_NAME_CALL_PRICE)) == expected_split_token_call_price,
            0
        );
        assert!(
            property_map::read_u64<SplitToken>(&split_token_object, &string::utf8(PROPERTY_NAME_CALL_THRESHOLD)) == expected_split_token_call_threshold,
            0
        );
        assert!(
            property_map::read_u64<SplitToken>(&split_token_object, &string::utf8(PROPERTY_NAME_MAX_SUPPLY)) == expected_split_token_supply,
            0
        );
        assert!(
            property_map::read_string<SplitToken>(&split_token_object, &string::utf8(PROPERTY_NAME_NFT_TOKEN_NAME)) == string::utf8(nf_token_name),
            0
        );
        assert!(
            property_map::read_string<SplitToken>(&split_token_object, &string::utf8(PROPERTY_NAME_NFT_COLLECTION_NAME)) == string::utf8(nf_token_collection_name),
            0
        );
        assert!(
            property_map::read_address<SplitToken>(&split_token_object, &string::utf8(PROPERTY_NAME_NFT_CREATOR_ADDRESS)) == account_address,
            0
        );
        assert!(split_balance(account_address, split_token_object) == expected_split_token_supply, 0);
        assert!(split_balance(creator_address, split_token_object) == 0, 0);

        assert!(object::owner(nf_token_object) == resource_account_address, 0);

        let transfer_amount = 300_0000_0000;
        primary_fungible_store::transfer<SplitToken>(account, split_token_object, receiver_address, transfer_amount);
        assert!(split_balance(account_address, split_token_object) == expected_split_token_supply - transfer_amount, 0);
        assert!(split_balance(receiver_address, split_token_object) == transfer_amount, 0);

        let split_event_count = get_split_events_count();
        assert!(split_event_count == 1, EWrongNumberOfEventsEmitted);
        let redeem_event_count = get_redeem_events_count();
        assert!(redeem_event_count == 0, EWrongNumberOfEventsEmitted);
        let call_event_count = get_call_events_count();
        assert!(call_event_count == 0, EWrongNumberOfEventsEmitted);
        let exchange_event_count = get_exchange_events_count();
        assert!(exchange_event_count == 0, EWrongNumberOfEventsEmitted);
    }

    #[test(creator = @overmind, account = @0xA)]
    fun test_split_success_2_NFTs_from_1_collections(
        creator: &signer,
        account: &signer
    ) acquires State, SplitToken {

        let creator_address = signer::address_of(creator);
        let account_address = signer::address_of(account);
        let receiver_address = @0xB;
        account::create_account_for_test(creator_address);
        account::create_account_for_test(account_address);
        account::create_account_for_test(receiver_address);

        init_module(creator);

        let nf_token_collection_name_1 = b"collection1";
        let nf_token_name_1 = b"token1";
        let nf_token_name_2 = b"token2";

        create_nft_collection(account, nf_token_collection_name_1);
        let nf_token_object_1 = mint_nft_1(account, nf_token_collection_name_1, nf_token_name_1);
        let nf_token_address_1 = object::object_address<TestToken1>(&nf_token_object_1);
        let nf_token_object_2 = mint_nft_1(account, nf_token_collection_name_1, nf_token_name_2);
        let nf_token_address_2 = object::object_address<TestToken1>(&nf_token_object_2);

        let expected_split_token_name_1 = b"split token 1";
        let expected_split_token_symbol_1 = b"SPLIT 1";
        let expected_split_token_description_1 = b"split token desc 1";
        let expected_split_token_call_threshold_1 = 900_0000_0000;
        let expected_split_token_call_price_1 = 1_0000_0000;
        let expected_split_token_supply_1 = 1000_0000_0000;
        let expected_split_token_icon_uri_1 = b"icon uri 1 ";
        let expected_split_token_project_uri_1 = b"project uri 1";
        split<TestToken1>(
            account,
            nf_token_address_1,
            string::utf8(expected_split_token_name_1),
            string::utf8(expected_split_token_symbol_1),
            string::utf8(expected_split_token_description_1),
            expected_split_token_supply_1,
            expected_split_token_call_threshold_1,
            expected_split_token_call_price_1,
            string::utf8(expected_split_token_icon_uri_1),
            string::utf8(expected_split_token_project_uri_1)
        );

        let expected_split_token_name_2 = b"split token 2";
        let expected_split_token_symbol_2 = b"SPLIT 2";
        let expected_split_token_description_2 = b"split token desc 2";
        let expected_split_token_call_threshold_2 = 560_0000_0000;
        let expected_split_token_call_price_2 = 0;
        let expected_split_token_supply_2 = 1001_0000_0000;
        let expected_split_token_icon_uri_2 = b"icon uri 2 ";
        let expected_split_token_project_uri_2 = b"project uri 2";
        split<TestToken1>(
            account,
            nf_token_address_2,
            string::utf8(expected_split_token_name_2),
            string::utf8(expected_split_token_symbol_2),
            string::utf8(expected_split_token_description_2),
            expected_split_token_supply_2,
            expected_split_token_call_threshold_2,
            expected_split_token_call_price_2,
            string::utf8(expected_split_token_icon_uri_2),
            string::utf8(expected_split_token_project_uri_2)
        );

        let state = borrow_global<State>(creator_address);
        let resource_account_signer_cap_ref = &state.signer_capability;
        let resource_account_address = account::get_signer_capability_address(resource_account_signer_cap_ref);

        let split_token_address_1 = split_token_address(expected_split_token_name_1);
        let expected_split_token_address_1 = token::create_token_address(
            &resource_account_address,
            &string::utf8(SPLIT_COLLECTION_NAME),
            &string::utf8(expected_split_token_name_1)
        );
        let split_token_object_1 = object::address_to_object<SplitToken>(split_token_address(expected_split_token_name_1));
        assert!(split_token_address_1 == expected_split_token_address_1, 0);
        assert!(
            token::creator<SplitToken>(split_token_object_1) == resource_account_address,
            0
        );
        assert!(
            token::collection_name<SplitToken>(split_token_object_1) == string::utf8(SPLIT_COLLECTION_NAME),
            0
        );
        assert!(
            token::name<SplitToken>(split_token_object_1) == string::utf8(expected_split_token_name_1),
            0
        );
        assert!(
            token::description<SplitToken>(split_token_object_1) == string::utf8(expected_split_token_description_1),
            0
        );
        assert!(
            token::uri<SplitToken>(split_token_object_1) == string::utf8(expected_split_token_project_uri_1),
            0
        );
        assert!(
            option::is_none<royalty::Royalty>(&token::royalty<SplitToken>(split_token_object_1)) == true,
            0
        );
        assert!(
            property_map::read_address<SplitToken>(&split_token_object_1, &string::utf8(PROPERTY_NAME_NFT_ADDRESS)) == nf_token_address_1,
            0
        );
        assert!(
            property_map::read_u64<SplitToken>(&split_token_object_1, &string::utf8(PROPERTY_NAME_CALL_PRICE)) == expected_split_token_call_price_1,
            0
        );
        assert!(
            property_map::read_u64<SplitToken>(&split_token_object_1, &string::utf8(PROPERTY_NAME_CALL_THRESHOLD)) == expected_split_token_call_threshold_1,
            0
        );
        assert!(
            property_map::read_u64<SplitToken>(&split_token_object_1, &string::utf8(PROPERTY_NAME_MAX_SUPPLY)) == expected_split_token_supply_1,
            0
        );
        assert!(
            property_map::read_string<SplitToken>(&split_token_object_1, &string::utf8(PROPERTY_NAME_NFT_TOKEN_NAME)) == string::utf8(nf_token_name_1),
            0
        );
        assert!(
            property_map::read_string<SplitToken>(&split_token_object_1, &string::utf8(PROPERTY_NAME_NFT_COLLECTION_NAME)) == string::utf8(nf_token_collection_name_1),
            0
        );
        assert!(
            property_map::read_address<SplitToken>(&split_token_object_1, &string::utf8(PROPERTY_NAME_NFT_CREATOR_ADDRESS)) == account_address,
            0
        );
        assert!(split_balance(account_address, split_token_object_1) == expected_split_token_supply_1, 0);
        assert!(split_balance(creator_address, split_token_object_1) == 0, 0);

        let split_token_address_2 = split_token_address(expected_split_token_name_2);
        let expected_split_token_address_2 = token::create_token_address(
            &resource_account_address,
            &string::utf8(SPLIT_COLLECTION_NAME),
            &string::utf8(expected_split_token_name_2)
        );
        let split_token_object_2 = object::address_to_object<SplitToken>(split_token_address(expected_split_token_name_2));
        assert!(split_token_address_2 == expected_split_token_address_2, 0);
        assert!(
            token::creator<SplitToken>(split_token_object_2) == resource_account_address,
            0
        );
        assert!(
            token::collection_name<SplitToken>(split_token_object_2) == string::utf8(SPLIT_COLLECTION_NAME),
            0
        );
        assert!(
            token::name<SplitToken>(split_token_object_2) == string::utf8(expected_split_token_name_2),
            0
        );
        assert!(
            token::description<SplitToken>(split_token_object_2) == string::utf8(expected_split_token_description_2),
            0
        );
        assert!(
            token::uri<SplitToken>(split_token_object_2) == string::utf8(expected_split_token_project_uri_2),
            0
        );
        assert!(
            option::is_none<royalty::Royalty>(&token::royalty<SplitToken>(split_token_object_2)) == true,
            0
        );
        assert!(
            property_map::read_address<SplitToken>(&split_token_object_2, &string::utf8(PROPERTY_NAME_NFT_ADDRESS)) == nf_token_address_2,
            0
        );
        assert!(
            property_map::read_u64<SplitToken>(&split_token_object_2, &string::utf8(PROPERTY_NAME_CALL_PRICE)) == expected_split_token_call_price_2,
            0
        );
        assert!(
            property_map::read_u64<SplitToken>(&split_token_object_2, &string::utf8(PROPERTY_NAME_CALL_THRESHOLD)) == expected_split_token_call_threshold_2,
            0
        );
        assert!(
            property_map::read_u64<SplitToken>(&split_token_object_2, &string::utf8(PROPERTY_NAME_MAX_SUPPLY)) == expected_split_token_supply_2,
            0
        );
        assert!(
            property_map::read_string<SplitToken>(&split_token_object_2, &string::utf8(PROPERTY_NAME_NFT_TOKEN_NAME)) == string::utf8(nf_token_name_2),
            0
        );
        assert!(
            property_map::read_string<SplitToken>(&split_token_object_2, &string::utf8(PROPERTY_NAME_NFT_COLLECTION_NAME)) == string::utf8(nf_token_collection_name_1),
            0
        );
        assert!(
            property_map::read_address<SplitToken>(&split_token_object_2, &string::utf8(PROPERTY_NAME_NFT_CREATOR_ADDRESS)) == account_address,
            0
        );
        assert!(split_balance(account_address, split_token_object_2) == expected_split_token_supply_2, 0);
        assert!(split_balance(creator_address, split_token_object_2) == 0, 0);

        assert!(object::owner(nf_token_object_1) == resource_account_address, 0);

        assert!(object::owner(nf_token_object_2) == resource_account_address, 0);

        let transfer_amount_1 = 300_0000_0000;
        primary_fungible_store::transfer<SplitToken>(account, split_token_object_1, receiver_address, transfer_amount_1);
        assert!(split_balance(account_address, split_token_object_1) == expected_split_token_supply_1 - transfer_amount_1, 0);
        assert!(split_balance(receiver_address, split_token_object_1) == transfer_amount_1, 0);

        let transfer_amount_2 = 3_0000_0000;
        primary_fungible_store::transfer<SplitToken>(account, split_token_object_2, receiver_address, transfer_amount_2);
        assert!(split_balance(account_address, split_token_object_2) == expected_split_token_supply_2 - transfer_amount_2, 0);
        assert!(split_balance(receiver_address, split_token_object_2) == transfer_amount_2, 0); 

        let split_event_count = get_split_events_count();
        assert!(split_event_count == 2, EWrongNumberOfEventsEmitted);
        let redeem_event_count = get_redeem_events_count();
        assert!(redeem_event_count == 0, EWrongNumberOfEventsEmitted);
        let call_event_count = get_call_events_count();
        assert!(call_event_count == 0, EWrongNumberOfEventsEmitted);
        let exchange_event_count = get_exchange_events_count();
        assert!(exchange_event_count == 0, EWrongNumberOfEventsEmitted);   
    }

    #[test(creator = @overmind, account = @0xA)]
    fun test_split_success_2_NFTs_from_2_collections(
        creator: &signer,
        account: &signer
    ) acquires State, SplitToken {

        let creator_address = signer::address_of(creator);
        let account_address = signer::address_of(account);
        let receiver_address = @0xB;
        account::create_account_for_test(creator_address);
        account::create_account_for_test(account_address);
        account::create_account_for_test(receiver_address);

        init_module(creator);

        let nf_token_collection_name_1 = b"collection1";
        let nf_token_collection_name_2 = b"collection2";
        let nf_token_name_1 = b"token1";
        let nf_token_name_2 = b"token2";

        create_nft_collection(account, nf_token_collection_name_1);
        let nf_token_object_1 = mint_nft_1(account, nf_token_collection_name_1, nf_token_name_1);
        let nf_token_address_1 = object::object_address<TestToken1>(&nf_token_object_1);
        create_nft_collection(account, nf_token_collection_name_2);
        let nf_token_object_2 = mint_nft_2(account, nf_token_collection_name_1, nf_token_name_2);
        let nf_token_address_2 = object::object_address<TestToken2>(&nf_token_object_2);

        let expected_split_token_name_1 = b"split token 1";
        let expected_split_token_symbol_1 = b"SPLIT 1";
        let expected_split_token_description_1 = b"split token desc 1";
        let expected_split_token_call_threshold_1 = 900_0000_0000;
        let expected_split_token_call_price_1 = 1_0000_0000;
        let expected_split_token_supply_1 = 1000_0000_0000;
        let expected_split_token_icon_uri_1 = b"icon uri 1 ";
        let expected_split_token_project_uri_1 = b"project uri 1";
        split<TestToken1>(
            account,
            nf_token_address_1,
            string::utf8(expected_split_token_name_1),
            string::utf8(expected_split_token_symbol_1),
            string::utf8(expected_split_token_description_1),
            expected_split_token_supply_1,
            expected_split_token_call_threshold_1,
            expected_split_token_call_price_1,
            string::utf8(expected_split_token_icon_uri_1),
            string::utf8(expected_split_token_project_uri_1)
        );

        let expected_split_token_name_2 = b"split token 2";
        let expected_split_token_symbol_2 = b"SPLIT 2";
        let expected_split_token_description_2 = b"split token desc 2";
        let expected_split_token_call_threshold_2 = 560_0000_0000;
        let expected_split_token_call_price_2 = 0;
        let expected_split_token_supply_2 = 1001_0000_0000;
        let expected_split_token_icon_uri_2 = b"icon uri 2 ";
        let expected_split_token_project_uri_2 = b"project uri 2";
        split<TestToken2>(
            account,
            nf_token_address_2,
            string::utf8(expected_split_token_name_2),
            string::utf8(expected_split_token_symbol_2),
            string::utf8(expected_split_token_description_2),
            expected_split_token_supply_2,
            expected_split_token_call_threshold_2,
            expected_split_token_call_price_2,
            string::utf8(expected_split_token_icon_uri_2),
            string::utf8(expected_split_token_project_uri_2)
        );

        let state = borrow_global<State>(creator_address);
        let resource_account_signer_cap_ref = &state.signer_capability;
        let resource_account_address = account::get_signer_capability_address(resource_account_signer_cap_ref);

        let split_token_address_1 = split_token_address(expected_split_token_name_1);
        let expected_split_token_address_1 = token::create_token_address(
            &resource_account_address,
            &string::utf8(SPLIT_COLLECTION_NAME),
            &string::utf8(expected_split_token_name_1)
        );
        let split_token_object_1 = object::address_to_object<SplitToken>(split_token_address(expected_split_token_name_1));
        assert!(split_token_address_1 == expected_split_token_address_1, 0);
        assert!(
            token::creator<SplitToken>(split_token_object_1) == resource_account_address,
            0
        );
        assert!(
            token::collection_name<SplitToken>(split_token_object_1) == string::utf8(SPLIT_COLLECTION_NAME),
            0
        );
        assert!(
            token::name<SplitToken>(split_token_object_1) == string::utf8(expected_split_token_name_1),
            0
        );
        assert!(
            token::description<SplitToken>(split_token_object_1) == string::utf8(expected_split_token_description_1),
            0
        );
        assert!(
            token::uri<SplitToken>(split_token_object_1) == string::utf8(expected_split_token_project_uri_1),
            0
        );
        assert!(
            option::is_none<royalty::Royalty>(&token::royalty<SplitToken>(split_token_object_1)) == true,
            0
        );
        assert!(
            property_map::read_address<SplitToken>(&split_token_object_1, &string::utf8(PROPERTY_NAME_NFT_ADDRESS)) == nf_token_address_1,
            0
        );
        assert!(
            property_map::read_u64<SplitToken>(&split_token_object_1, &string::utf8(PROPERTY_NAME_CALL_PRICE)) == expected_split_token_call_price_1,
            0
        );
        assert!(
            property_map::read_u64<SplitToken>(&split_token_object_1, &string::utf8(PROPERTY_NAME_CALL_THRESHOLD)) == expected_split_token_call_threshold_1,
            0
        );
        assert!(
            property_map::read_u64<SplitToken>(&split_token_object_1, &string::utf8(PROPERTY_NAME_MAX_SUPPLY)) == expected_split_token_supply_1,
            0
        );
        assert!(
            property_map::read_string<SplitToken>(&split_token_object_1, &string::utf8(PROPERTY_NAME_NFT_TOKEN_NAME)) == string::utf8(nf_token_name_1),
            0
        );
        assert!(
            property_map::read_string<SplitToken>(&split_token_object_1, &string::utf8(PROPERTY_NAME_NFT_COLLECTION_NAME)) == string::utf8(nf_token_collection_name_1),
            0
        );
        assert!(
            property_map::read_address<SplitToken>(&split_token_object_1, &string::utf8(PROPERTY_NAME_NFT_CREATOR_ADDRESS)) == account_address,
            0
        );
        assert!(split_balance(account_address, split_token_object_1) == expected_split_token_supply_1, 0);
        assert!(split_balance(creator_address, split_token_object_1) == 0, 0);

        let split_token_address_2 = split_token_address(expected_split_token_name_2);
        let expected_split_token_address_2 = token::create_token_address(
            &resource_account_address,
            &string::utf8(SPLIT_COLLECTION_NAME),
            &string::utf8(expected_split_token_name_2)
        );
        let split_token_object_2 = object::address_to_object<SplitToken>(split_token_address(expected_split_token_name_2));
        assert!(split_token_address_2 == expected_split_token_address_2, 0);
        assert!(
            token::creator<SplitToken>(split_token_object_2) == resource_account_address,
            0
        );
        assert!(
            token::collection_name<SplitToken>(split_token_object_2) == string::utf8(SPLIT_COLLECTION_NAME),
            0
        );
        assert!(
            token::name<SplitToken>(split_token_object_2) == string::utf8(expected_split_token_name_2),
            0
        );
        assert!(
            token::description<SplitToken>(split_token_object_2) == string::utf8(expected_split_token_description_2),
            0
        );
        assert!(
            token::uri<SplitToken>(split_token_object_2) == string::utf8(expected_split_token_project_uri_2),
            0
        );
        assert!(
            option::is_none<royalty::Royalty>(&token::royalty<SplitToken>(split_token_object_2)) == true,
            0
        );
        assert!(
            property_map::read_address<SplitToken>(&split_token_object_2, &string::utf8(PROPERTY_NAME_NFT_ADDRESS)) == nf_token_address_2,
            0
        );
        assert!(
            property_map::read_u64<SplitToken>(&split_token_object_2, &string::utf8(PROPERTY_NAME_CALL_PRICE)) == expected_split_token_call_price_2,
            0
        );
        assert!(
            property_map::read_u64<SplitToken>(&split_token_object_2, &string::utf8(PROPERTY_NAME_CALL_THRESHOLD)) == expected_split_token_call_threshold_2,
            0
        );
        assert!(
            property_map::read_u64<SplitToken>(&split_token_object_2, &string::utf8(PROPERTY_NAME_MAX_SUPPLY)) == expected_split_token_supply_2,
            0
        );
        assert!(
            property_map::read_string<SplitToken>(&split_token_object_2, &string::utf8(PROPERTY_NAME_NFT_TOKEN_NAME)) == string::utf8(nf_token_name_2),
            0
        );
        assert!(
            property_map::read_string<SplitToken>(&split_token_object_2, &string::utf8(PROPERTY_NAME_NFT_COLLECTION_NAME)) == string::utf8(nf_token_collection_name_1),
            0
        );
        assert!(
            property_map::read_address<SplitToken>(&split_token_object_2, &string::utf8(PROPERTY_NAME_NFT_CREATOR_ADDRESS)) == account_address,
            0
        );
        assert!(split_balance(account_address, split_token_object_2) == expected_split_token_supply_2, 0);
        assert!(split_balance(creator_address, split_token_object_2) == 0, 0);

        assert!(object::owner(nf_token_object_1) == resource_account_address, 0);

        assert!(object::owner(nf_token_object_2) == resource_account_address, 0);

        let transfer_amount_1 = 300_0000_0000;
        primary_fungible_store::transfer<SplitToken>(account, split_token_object_1, receiver_address, transfer_amount_1);
        assert!(split_balance(account_address, split_token_object_1) == expected_split_token_supply_1 - transfer_amount_1, 0);
        assert!(split_balance(receiver_address, split_token_object_1) == transfer_amount_1, 0);

        let transfer_amount_2 = 3_0000_0000;
        primary_fungible_store::transfer<SplitToken>(account, split_token_object_2, receiver_address, transfer_amount_2);
        assert!(split_balance(account_address, split_token_object_2) == expected_split_token_supply_2 - transfer_amount_2, 0);
        assert!(split_balance(receiver_address, split_token_object_2) == transfer_amount_2, 0);

        let split_event_count = get_split_events_count();
        assert!(split_event_count == 2, EWrongNumberOfEventsEmitted);
        let redeem_event_count = get_redeem_events_count();
        assert!(redeem_event_count == 0, EWrongNumberOfEventsEmitted);
        let call_event_count = get_call_events_count();
        assert!(call_event_count == 0, EWrongNumberOfEventsEmitted);
        let exchange_event_count = get_exchange_events_count();
        assert!(exchange_event_count == 0, EWrongNumberOfEventsEmitted);
    }

    #[test(creator = @overmind, account = @0xA)]
    #[expected_failure(abort_code = EAccountDoesNotOwnNft)]
    fun test_split_failure_does_not_own_nft(
        creator: &signer,
        account: &signer
    ) acquires State, SplitToken {
        let creator_address = signer::address_of(creator);
        let account_address = signer::address_of(account);
        let receiver_address = @0xB;
        account::create_account_for_test(creator_address);
        account::create_account_for_test(account_address);
        account::create_account_for_test(receiver_address);

        init_module(creator);

        let nf_token_collection_name = b"collection1";
        let nf_token_name = b"token1";

        create_nft_collection(account, nf_token_collection_name);
        let nf_token_object = mint_nft_1(account, nf_token_collection_name, nf_token_name);
        let nf_token_address = object::object_address<TestToken1>(&nf_token_object);

        object::transfer<TestToken1>(account, nf_token_object, receiver_address);

        let expected_split_token_name = b"split token";
        let expected_split_token_symbol = b"SPLIT";
        let expected_split_token_description = b"split token desc";
        let expected_split_token_call_threshold = 900_0000_0000;
        let expected_split_token_call_price = 1_0000_0000;
        let expected_split_token_supply = 1000_0000_0000;
        let expected_split_token_icon_uri = b"icon uri";
        let expected_split_token_project_uri = b"project uri";
        split<TestToken1>(
            account,
            nf_token_address,
            string::utf8(expected_split_token_name),
            string::utf8(expected_split_token_symbol),
            string::utf8(expected_split_token_description),
            expected_split_token_supply,
            expected_split_token_call_threshold,
            expected_split_token_call_price,
            string::utf8(expected_split_token_icon_uri),
            string::utf8(expected_split_token_project_uri)
        );
    }

    #[test(creator = @overmind, account = @0xA)]
    #[expected_failure(abort_code = EThresholdAmountIsGreaterThanTokenSupply)]
    fun test_split_failure_threshold_greater_than_supply(
        creator: &signer,
        account: &signer
    ) acquires State, SplitToken {
        let creator_address = signer::address_of(creator);
        let account_address = signer::address_of(account);
        let receiver_address = @0xB;
        account::create_account_for_test(creator_address);
        account::create_account_for_test(account_address);
        account::create_account_for_test(receiver_address);

        init_module(creator);

        let nf_token_collection_name = b"collection1";
        let nf_token_name = b"token1";

        create_nft_collection(account, nf_token_collection_name);
        let nf_token_object = mint_nft_1(account, nf_token_collection_name, nf_token_name);
        let nf_token_address = object::object_address<TestToken1>(&nf_token_object);

        let expected_split_token_name = b"split token";
        let expected_split_token_symbol = b"SPLIT";
        let expected_split_token_description = b"split token desc";
        let expected_split_token_call_threshold = 1010_0000_0000;
        let expected_split_token_call_price = 1_0000_0000;
        let expected_split_token_supply = 1000_0000_0000;
        let expected_split_token_icon_uri = b"icon uri";
        let expected_split_token_project_uri = b"project uri";
        split<TestToken1>(
            account,
            nf_token_address,
            string::utf8(expected_split_token_name),
            string::utf8(expected_split_token_symbol),
            string::utf8(expected_split_token_description),
            expected_split_token_supply,
            expected_split_token_call_threshold,
            expected_split_token_call_price,
            string::utf8(expected_split_token_icon_uri),
            string::utf8(expected_split_token_project_uri)
        );
    }

    #[test(creator = @overmind, account = @0xA)]
    #[expected_failure(abort_code = ETokenSupplyIsZero)]
    fun test_split_failure_split_token_supply_zero(
        creator: &signer,
        account: &signer
    ) acquires State, SplitToken {
        let creator_address = signer::address_of(creator);
        let account_address = signer::address_of(account);
        let receiver_address = @0xB;
        account::create_account_for_test(creator_address);
        account::create_account_for_test(account_address);
        account::create_account_for_test(receiver_address);

        init_module(creator);

        let nf_token_collection_name = b"collection1";
        let nf_token_name = b"token1";

        create_nft_collection(account, nf_token_collection_name);
        let nf_token_object = mint_nft_1(account, nf_token_collection_name, nf_token_name);
        let nf_token_address = object::object_address<TestToken1>(&nf_token_object);

        let expected_split_token_name = b"split token";
        let expected_split_token_symbol = b"SPLIT";
        let expected_split_token_description = b"split token desc";
        let expected_split_token_call_threshold = 0;
        let expected_split_token_call_price = 1_0000_0000;
        let expected_split_token_supply = 0;
        let expected_split_token_icon_uri = b"icon uri";
        let expected_split_token_project_uri = b"project uri";
        split<TestToken1>(
            account,
            nf_token_address,
            string::utf8(expected_split_token_name),
            string::utf8(expected_split_token_symbol),
            string::utf8(expected_split_token_description),
            expected_split_token_supply,
            expected_split_token_call_threshold,
            expected_split_token_call_price,
            string::utf8(expected_split_token_icon_uri),
            string::utf8(expected_split_token_project_uri)
        );
    }

    #[test(creator = @overmind, account = @0xA)]
    #[expected_failure(abort_code = ESplitTokenAlreadyExists)]
    fun test_split_failure_duplicate_naming(
        creator: &signer,
        account: &signer
    ) acquires State, SplitToken {
        let creator_address = signer::address_of(creator);
        let account_address = signer::address_of(account);
        let receiver_address = @0xB;
        account::create_account_for_test(creator_address);
        account::create_account_for_test(account_address);
        account::create_account_for_test(receiver_address);

        init_module(creator);

        let nf_token_collection_name_1 = b"collection1";
        let nf_token_name_1 = b"token1";
        let nf_token_name_2 = b"token2";

        create_nft_collection(account, nf_token_collection_name_1);
        let nf_token_object_1 = mint_nft_1(account, nf_token_collection_name_1, nf_token_name_1);
        let nf_token_address_1 = object::object_address<TestToken1>(&nf_token_object_1);
        let nf_token_object_2 = mint_nft_1(account, nf_token_collection_name_1, nf_token_name_2);
        let nf_token_address_2 = object::object_address<TestToken1>(&nf_token_object_2);


        let expected_split_token_name_1 = b"split token";
        let expected_split_token_symbol_1 = b"SPLIT";
        let expected_split_token_description_1 = b"split token desc";
        let expected_split_token_call_threshold_1 = 900_0000_0000;
        let expected_split_token_call_price_1 = 1_0000_0000;
        let expected_split_token_supply_1 = 1000_0000_0000;
        let expected_split_token_icon_uri_1 = b"icon uri";
        let expected_split_token_project_uri_1 = b"project uri";
        split<TestToken1>(
            account,
            nf_token_address_1,
            string::utf8(expected_split_token_name_1),
            string::utf8(expected_split_token_symbol_1),
            string::utf8(expected_split_token_description_1),
            expected_split_token_supply_1,
            expected_split_token_call_threshold_1,
            expected_split_token_call_price_1,
            string::utf8(expected_split_token_icon_uri_1),
            string::utf8(expected_split_token_project_uri_1)
        );

        split<TestToken1>(
            account,
            nf_token_address_2,
            string::utf8(expected_split_token_name_1),
            string::utf8(expected_split_token_symbol_1),
            string::utf8(expected_split_token_description_1),
            expected_split_token_supply_1,
            expected_split_token_call_threshold_1,
            expected_split_token_call_price_1,
            string::utf8(expected_split_token_icon_uri_1),
            string::utf8(expected_split_token_project_uri_1)
        );
    }

    #[test(creator = @overmind, account = @0xA)]
    #[expected_failure(abort_code = EThresholdAmountIsNotGreaterThanHalfOfSupply)]
    fun test_split_failure_threshold_half_or_below(
        creator: &signer,
        account: &signer
    ) acquires State, SplitToken {
        let creator_address = signer::address_of(creator);
        let account_address = signer::address_of(account);
        let receiver_address = @0xB;
        account::create_account_for_test(creator_address);
        account::create_account_for_test(account_address);
        account::create_account_for_test(receiver_address);

        init_module(creator);

        let nf_token_collection_name = b"collection1";
        let nf_token_name = b"token1";

        create_nft_collection(account, nf_token_collection_name);
        let nf_token_object = mint_nft_1(account, nf_token_collection_name, nf_token_name);
        let nf_token_address = object::object_address<TestToken1>(&nf_token_object);

        let expected_split_token_name = b"split token";
        let expected_split_token_symbol = b"SPLIT";
        let expected_split_token_description = b"split token desc";
        let expected_split_token_call_threshold = 10_0000_0000;
        let expected_split_token_call_price = 1_0000_0000;
        let expected_split_token_supply = 1000_0000_0000;
        let expected_split_token_icon_uri = b"icon uri";
        let expected_split_token_project_uri = b"project uri";
        split<TestToken1>(
            account,
            nf_token_address,
            string::utf8(expected_split_token_name),
            string::utf8(expected_split_token_symbol),
            string::utf8(expected_split_token_description),
            expected_split_token_supply,
            expected_split_token_call_threshold,
            expected_split_token_call_price,
            string::utf8(expected_split_token_icon_uri),
            string::utf8(expected_split_token_project_uri)
        );
    }

    #[test(creator = @overmind, account = @0xA)]
    fun test_redeem_success_1_NFT(
        creator: &signer,
        account: &signer
    ) acquires State, SplitToken {

        let creator_address = signer::address_of(creator);
        let account_address = signer::address_of(account);
        let receiver_address = @0xB;
        account::create_account_for_test(creator_address);
        account::create_account_for_test(account_address);
        account::create_account_for_test(receiver_address);

        init_module(creator);

        let nf_token_collection_name = b"collection1";
        let nf_token_name = b"token1";

        create_nft_collection(account, nf_token_collection_name);
        let nf_token_object = mint_nft_1(account, nf_token_collection_name, nf_token_name);
        let nf_token_address = object::object_address<TestToken1>(&nf_token_object);

        let expected_split_token_name = b"split token";
        let expected_split_token_symbol = b"SPLIT";
        let expected_split_token_description = b"split token desc";
        let expected_split_token_call_threshold = 900_0000_0000;
        let expected_split_token_call_price = 1_0000_0000;
        let expected_split_token_supply = 1000_0000_0000;
        let expected_split_token_icon_uri = b"icon uri";
        let expected_split_token_project_uri = b"project uri";
        split<TestToken1>(
            account,
            nf_token_address,
            string::utf8(expected_split_token_name),
            string::utf8(expected_split_token_symbol),
            string::utf8(expected_split_token_description),
            expected_split_token_supply,
            expected_split_token_call_threshold,
            expected_split_token_call_price,
            string::utf8(expected_split_token_icon_uri),
            string::utf8(expected_split_token_project_uri)
        );

        let state = borrow_global<State>(creator_address);
        let resource_account_signer_cap_ref = &state.signer_capability;
        let resource_account_address = account::get_signer_capability_address(resource_account_signer_cap_ref);

        let split_token_object = object::address_to_object<SplitToken>(split_token_address(expected_split_token_name));

        assert!(split_balance(account_address, split_token_object) == expected_split_token_supply, 0);
        assert!(split_balance(creator_address, split_token_object) == 0, 0);

        assert!(object::owner(nf_token_object) == resource_account_address, 0);

        redeem<TestToken1>(account, split_token_address(expected_split_token_name));

        assert!(split_balance(account_address, split_token_object) == 0, 0);

        assert!(object::owner(nf_token_object) == account_address, 0);

        let split_event_count = get_split_events_count();
        assert!(split_event_count == 1, EWrongNumberOfEventsEmitted);
        let redeem_event_count = get_redeem_events_count();
        assert!(redeem_event_count == 1, EWrongNumberOfEventsEmitted);
        let call_event_count = get_call_events_count();
        assert!(call_event_count == 0, EWrongNumberOfEventsEmitted);
        let exchange_event_count = get_exchange_events_count();
        assert!(exchange_event_count == 0, EWrongNumberOfEventsEmitted);
    }

    #[test(creator = @overmind, account = @0xA)]
    #[expected_failure(abort_code = ETokenBalanceIsNotEqualToTokenSupply)]
    fun test_redeem_failure_token_amount_below_full_supply(
        creator: &signer,
        account: &signer
    ) acquires State, SplitToken {

        let creator_address = signer::address_of(creator);
        let account_address = signer::address_of(account);
        let receiver_address = @0xB;
        account::create_account_for_test(creator_address);
        account::create_account_for_test(account_address);
        account::create_account_for_test(receiver_address);

        init_module(creator);

        let nf_token_collection_name = b"collection1";
        let nf_token_name = b"token1";

        create_nft_collection(account, nf_token_collection_name);
        let nf_token_object = mint_nft_1(account, nf_token_collection_name, nf_token_name);
        let nf_token_address = object::object_address<TestToken1>(&nf_token_object);

        let expected_split_token_name = b"split token";
        let expected_split_token_symbol = b"SPLIT";
        let expected_split_token_description = b"split token desc";
        let expected_split_token_call_threshold = 900_0000_0000;
        let expected_split_token_call_price = 1_0000_0000;
        let expected_split_token_supply = 1000_0000_0000;
        let expected_split_token_icon_uri = b"icon uri";
        let expected_split_token_project_uri = b"project uri";
        split<TestToken1>(
            account,
            nf_token_address,
            string::utf8(expected_split_token_name),
            string::utf8(expected_split_token_symbol),
            string::utf8(expected_split_token_description),
            expected_split_token_supply,
            expected_split_token_call_threshold,
            expected_split_token_call_price,
            string::utf8(expected_split_token_icon_uri),
            string::utf8(expected_split_token_project_uri)
        );

        let state = borrow_global<State>(creator_address);
        let resource_account_signer_cap_ref = &state.signer_capability;
        let resource_account_address = account::get_signer_capability_address(resource_account_signer_cap_ref);

        let split_token_object = object::address_to_object<SplitToken>(split_token_address(expected_split_token_name));

        assert!(split_balance(account_address, split_token_object) == expected_split_token_supply, 0);
        assert!(split_balance(creator_address, split_token_object) == 0, 0);

        assert!(object::owner(nf_token_object) == resource_account_address, 0);

        let transfer_amount = 300_0000_0000;
        primary_fungible_store::transfer<SplitToken>(account, split_token_object, receiver_address, transfer_amount);
        assert!(split_balance(account_address, split_token_object) == expected_split_token_supply - transfer_amount, 0);
        assert!(split_balance(receiver_address, split_token_object) == transfer_amount, 0);

        redeem<TestToken1>(account, split_token_address(expected_split_token_name));
    }

    #[test(creator = @overmind, account = @0xA)]
    #[expected_failure(abort_code = ENftIsNotOwnedByAccount)]
    fun test_redeem_failure_nft_has_already_been_redeemed(
        creator: &signer,
        account: &signer
    ) acquires State, SplitToken {

        let creator_address = signer::address_of(creator);
        let account_address = signer::address_of(account);
        let receiver_address = @0xB;
        account::create_account_for_test(creator_address);
        account::create_account_for_test(account_address);
        account::create_account_for_test(receiver_address);

        init_module(creator);

        let nf_token_collection_name = b"collection1";
        let nf_token_name = b"token1";

        create_nft_collection(account, nf_token_collection_name);
        let nf_token_object = mint_nft_1(account, nf_token_collection_name, nf_token_name);
        let nf_token_address = object::object_address<TestToken1>(&nf_token_object);

        let expected_split_token_name = b"split token";
        let expected_split_token_symbol = b"SPLIT";
        let expected_split_token_description = b"split token desc";
        let expected_split_token_call_threshold = 900_0000_0000;
        let expected_split_token_call_price = 1_0000_0000;
        let expected_split_token_supply = 1000_0000_0000;
        let expected_split_token_icon_uri = b"icon uri";
        let expected_split_token_project_uri = b"project uri";
        split<TestToken1>(
            account,
            nf_token_address,
            string::utf8(expected_split_token_name),
            string::utf8(expected_split_token_symbol),
            string::utf8(expected_split_token_description),
            expected_split_token_supply,
            expected_split_token_call_threshold,
            expected_split_token_call_price,
            string::utf8(expected_split_token_icon_uri),
            string::utf8(expected_split_token_project_uri)
        );

        let state = borrow_global<State>(creator_address);
        let resource_account_signer_cap_ref = &state.signer_capability;
        let resource_account_address = account::get_signer_capability_address(resource_account_signer_cap_ref);

        let split_token_object = object::address_to_object<SplitToken>(split_token_address(expected_split_token_name));

        assert!(split_balance(account_address, split_token_object) == expected_split_token_supply, 0);
        assert!(split_balance(creator_address, split_token_object) == 0, 0);

        assert!(object::owner(nf_token_object) == resource_account_address, 0);

        redeem<TestToken1>(account, split_token_address(expected_split_token_name));

        redeem<TestToken1>(account, split_token_address(expected_split_token_name));
    }

    #[test(aptos_framework = @0x1, creator = @overmind, account = @0xA)]
    fun test_call_success_1_NFT_full_amount(
        aptos_framework: &signer,
        creator: &signer,
        account: &signer
    ) acquires State, SplitToken {

        let (burn_cap, mint_cap) = aptos_coin::initialize_for_test(aptos_framework);

        let creator_address = signer::address_of(creator);
        let account_address = signer::address_of(account);
        let receiver_address = @0xB;
        account::create_account_for_test(creator_address);
        account::create_account_for_test(account_address);
        account::create_account_for_test(receiver_address);

        coin::register<AptosCoin>(creator);
        coin::register<AptosCoin>(account);

        init_module(creator);

        let nf_token_collection_name = b"collection1";
        let nf_token_name = b"token1";

        create_nft_collection(account, nf_token_collection_name);
        let nf_token_object = mint_nft_1(account, nf_token_collection_name, nf_token_name);
        let nf_token_address = object::object_address<TestToken1>(&nf_token_object);

        let expected_split_token_name = b"split token";
        let expected_split_token_symbol = b"SPLIT";
        let expected_split_token_description = b"split token desc";
        let expected_split_token_call_threshold = 900_0000_0000;
        let expected_split_token_call_price = 1_0000_0000;
        let expected_split_token_supply = 1000_0000_0000;
        let expected_split_token_icon_uri = b"icon uri";
        let expected_split_token_project_uri = b"project uri";
        split<TestToken1>(
            account,
            nf_token_address,
            string::utf8(expected_split_token_name),
            string::utf8(expected_split_token_symbol),
            string::utf8(expected_split_token_description),
            expected_split_token_supply,
            expected_split_token_call_threshold,
            expected_split_token_call_price,
            string::utf8(expected_split_token_icon_uri),
            string::utf8(expected_split_token_project_uri)
        );

        let state = borrow_global<State>(creator_address);
        let resource_account_signer_cap_ref = &state.signer_capability;
        let resource_account_address = account::get_signer_capability_address(resource_account_signer_cap_ref);

        let split_token_object = object::address_to_object<SplitToken>(split_token_address(expected_split_token_name));

        assert!(split_balance(account_address, split_token_object) == expected_split_token_supply, 0);
        assert!(split_balance(creator_address, split_token_object) == 0, 0);

        assert!(object::owner(nf_token_object) == resource_account_address, 0);

        call<TestToken1>(account, split_token_address(expected_split_token_name));

        assert!(split_balance(account_address, split_token_object) == 0, 0);

        assert!(object::owner(nf_token_object) == account_address, 0);

        coin::destroy_burn_cap(burn_cap);
        coin::destroy_mint_cap(mint_cap);

        let split_event_count = get_split_events_count();
        assert!(split_event_count == 1, EWrongNumberOfEventsEmitted);
        let redeem_event_count = get_redeem_events_count();
        assert!(redeem_event_count == 0, EWrongNumberOfEventsEmitted);
        let call_event_count = get_call_events_count();
        assert!(call_event_count == 1, EWrongNumberOfEventsEmitted);
        let exchange_event_count = get_exchange_events_count();
        assert!(exchange_event_count == 0, EWrongNumberOfEventsEmitted);
    }


    #[test(aptos_framework = @0x1, creator = @overmind, account = @0xA, receiver = @0xB)]
    fun test_call_success_1_NFT_partial_amount(
        aptos_framework: &signer,
        creator: &signer,
        account: &signer
    ) acquires State, SplitToken {

        let (burn_cap, mint_cap) = aptos_coin::initialize_for_test(aptos_framework);

        let creator_address = signer::address_of(creator);
        let account_address = signer::address_of(account);
        let receiver_address = @0xB;
        account::create_account_for_test(creator_address);
        account::create_account_for_test(account_address);
        account::create_account_for_test(receiver_address);

        coin::register<AptosCoin>(creator);
        coin::register<AptosCoin>(account);

        init_module(creator);

        let nf_token_collection_name = b"collection1";
        let nf_token_name = b"token1";

        create_nft_collection(account, nf_token_collection_name);
        let nf_token_object = mint_nft_1(account, nf_token_collection_name, nf_token_name);
        let nf_token_address = object::object_address<TestToken1>(&nf_token_object);

        let expected_split_token_name = b"split token";
        let expected_split_token_symbol = b"SPLIT";
        let expected_split_token_description = b"split token desc";
        let expected_split_token_call_threshold = 900_0000_0000;
        let expected_split_token_call_price = 1_0000_0000;
        let expected_split_token_supply = 1000_0000_0000;
        let expected_split_token_icon_uri = b"icon uri";
        let expected_split_token_project_uri = b"project uri";
        split<TestToken1>(
            account,
            nf_token_address,
            string::utf8(expected_split_token_name),
            string::utf8(expected_split_token_symbol),
            string::utf8(expected_split_token_description),
            expected_split_token_supply,
            expected_split_token_call_threshold,
            expected_split_token_call_price,
            string::utf8(expected_split_token_icon_uri),
            string::utf8(expected_split_token_project_uri)
        );

        let state = borrow_global<State>(creator_address);
        let resource_account_signer_cap_ref = &state.signer_capability;
        let resource_account_address = account::get_signer_capability_address(resource_account_signer_cap_ref);

        let split_token_object = object::address_to_object<SplitToken>(split_token_address(expected_split_token_name));

        assert!(split_balance(account_address, split_token_object) == expected_split_token_supply, 0);
        assert!(split_balance(creator_address, split_token_object) == 0, 0);

        assert!(object::owner(nf_token_object) == resource_account_address, 0);

        let transfer_amount = 50_0000_0000;
        primary_fungible_store::transfer<SplitToken>(account, split_token_object, receiver_address, transfer_amount);
        assert!(split_balance(account_address, split_token_object) == expected_split_token_supply - transfer_amount, 0);
        assert!(split_balance(receiver_address, split_token_object) == transfer_amount, 0);

        let expected_aptos_call_payment = expected_split_token_call_price * transfer_amount;
        let coins = coin::mint(expected_aptos_call_payment, &mint_cap);
        coin::deposit(account_address, coins);

        call<TestToken1>(account, split_token_address(expected_split_token_name));

        assert!(split_balance(account_address, split_token_object) == 0, 0);
        assert!(split_balance(receiver_address, split_token_object) == transfer_amount, 0);

        assert!(coin::balance<AptosCoin>(account_address) == 0, 0);
        assert!(coin::balance<AptosCoin>(resource_account_address) == expected_aptos_call_payment, 0);

        assert!(object::owner(nf_token_object) == account_address, 0);

        coin::destroy_burn_cap(burn_cap);
        coin::destroy_mint_cap(mint_cap);

        let split_event_count = get_split_events_count();
        assert!(split_event_count == 1, EWrongNumberOfEventsEmitted);
        let redeem_event_count = get_redeem_events_count();
        assert!(redeem_event_count == 0, EWrongNumberOfEventsEmitted);
        let call_event_count = get_call_events_count();
        assert!(call_event_count == 1, EWrongNumberOfEventsEmitted);
        let exchange_event_count = get_exchange_events_count();
        assert!(exchange_event_count == 0, EWrongNumberOfEventsEmitted);
    }

    #[test(aptos_framework = @0x1, creator = @overmind, account = @0xA)]
    #[expected_failure(abort_code = ESplitTokenBalanceIsLessThanCallThreshold)]
    fun test_call_failure_token_balance_below_call_threshold(
        aptos_framework: &signer,
        creator: &signer,
        account: &signer
    ) acquires State, SplitToken {

        let (burn_cap, mint_cap) = aptos_coin::initialize_for_test(aptos_framework);

        let creator_address = signer::address_of(creator);
        let account_address = signer::address_of(account);
        let receiver_address = @0xB;
        account::create_account_for_test(creator_address);
        account::create_account_for_test(account_address);
        account::create_account_for_test(receiver_address);

        coin::register<AptosCoin>(creator);
        coin::register<AptosCoin>(account);

        init_module(creator);

        let nf_token_collection_name = b"collection1";
        let nf_token_name = b"token1";

        create_nft_collection(account, nf_token_collection_name);
        let nf_token_object = mint_nft_1(account, nf_token_collection_name, nf_token_name);
        let nf_token_address = object::object_address<TestToken1>(&nf_token_object);

        let expected_split_token_name = b"split token";
        let expected_split_token_symbol = b"SPLIT";
        let expected_split_token_description = b"split token desc";
        let expected_split_token_call_threshold = 900_0000_0000;
        let expected_split_token_call_price = 1_0000_0000;
        let expected_split_token_supply = 1000_0000_0000;
        let expected_split_token_icon_uri = b"icon uri";
        let expected_split_token_project_uri = b"project uri";
        split<TestToken1>(
            account,
            nf_token_address,
            string::utf8(expected_split_token_name),
            string::utf8(expected_split_token_symbol),
            string::utf8(expected_split_token_description),
            expected_split_token_supply,
            expected_split_token_call_threshold,
            expected_split_token_call_price,
            string::utf8(expected_split_token_icon_uri),
            string::utf8(expected_split_token_project_uri)
        );

        let state = borrow_global<State>(creator_address);
        let resource_account_signer_cap_ref = &state.signer_capability;
        let resource_account_address = account::get_signer_capability_address(resource_account_signer_cap_ref);

        let split_token_object = object::address_to_object<SplitToken>(split_token_address(expected_split_token_name));

        assert!(split_balance(account_address, split_token_object) == expected_split_token_supply, 0);
        assert!(split_balance(creator_address, split_token_object) == 0, 0);

        assert!(object::owner(nf_token_object) == resource_account_address, 0);

        let transfer_amount = 500_0000_0000;
        primary_fungible_store::transfer<SplitToken>(account, split_token_object, receiver_address, transfer_amount);
        assert!(split_balance(account_address, split_token_object) == expected_split_token_supply - transfer_amount, 0);
        assert!(split_balance(receiver_address, split_token_object) == transfer_amount, 0);

        let expected_aptos_call_payment = expected_split_token_call_price * transfer_amount;
        let coins = coin::mint(expected_aptos_call_payment, &mint_cap);
        coin::deposit(account_address, coins);

        call<TestToken1>(account, split_token_address(expected_split_token_name));

        coin::destroy_burn_cap(burn_cap);
        coin::destroy_mint_cap(mint_cap);
    }

    #[test(aptos_framework = @0x1, creator = @overmind, account = @0xA)]
    #[expected_failure(abort_code = EAptosCoinBalanceIsLessThanCallPayment)]
    fun test_call_failure_insufficient_aptos_coin_balance(
        aptos_framework: &signer,
        creator: &signer,
        account: &signer
    ) acquires State, SplitToken {

        let (burn_cap, mint_cap) = aptos_coin::initialize_for_test(aptos_framework);

        let creator_address = signer::address_of(creator);
        let account_address = signer::address_of(account);
        let receiver_address = @0xB;
        account::create_account_for_test(creator_address);
        account::create_account_for_test(account_address);
        account::create_account_for_test(receiver_address);

        coin::register<AptosCoin>(creator);
        coin::register<AptosCoin>(account);

        init_module(creator);

        let nf_token_collection_name = b"collection1";
        let nf_token_name = b"token1";

        create_nft_collection(account, nf_token_collection_name);
        let nf_token_object = mint_nft_1(account, nf_token_collection_name, nf_token_name);
        let nf_token_address = object::object_address<TestToken1>(&nf_token_object);

        let expected_split_token_name = b"split token";
        let expected_split_token_symbol = b"SPLIT";
        let expected_split_token_description = b"split token desc";
        let expected_split_token_call_threshold = 900_0000_0000;
        let expected_split_token_call_price = 1_0000_0000;
        let expected_split_token_supply = 1000_0000_0000;
        let expected_split_token_icon_uri = b"icon uri";
        let expected_split_token_project_uri = b"project uri";
        split<TestToken1>(
            account,
            nf_token_address,
            string::utf8(expected_split_token_name),
            string::utf8(expected_split_token_symbol),
            string::utf8(expected_split_token_description),
            expected_split_token_supply,
            expected_split_token_call_threshold,
            expected_split_token_call_price,
            string::utf8(expected_split_token_icon_uri),
            string::utf8(expected_split_token_project_uri)
        );

        let state = borrow_global<State>(creator_address);
        let resource_account_signer_cap_ref = &state.signer_capability;
        let resource_account_address = account::get_signer_capability_address(resource_account_signer_cap_ref);

        let split_token_object = object::address_to_object<SplitToken>(split_token_address(expected_split_token_name));

        assert!(split_balance(account_address, split_token_object) == expected_split_token_supply, 0);
        assert!(split_balance(creator_address, split_token_object) == 0, 0);

        assert!(object::owner(nf_token_object) == resource_account_address, 0);

        let transfer_amount = 5_0000_0000;
        primary_fungible_store::transfer<SplitToken>(account, split_token_object, receiver_address, transfer_amount);
        assert!(split_balance(account_address, split_token_object) == expected_split_token_supply - transfer_amount, 0);
        assert!(split_balance(receiver_address, split_token_object) == transfer_amount, 0);

        call<TestToken1>(account, split_token_address(expected_split_token_name));

        coin::destroy_burn_cap(burn_cap);
        coin::destroy_mint_cap(mint_cap);
    }

    #[test(aptos_framework = @0x1, creator = @overmind, account = @0xA, receiver = @0xB)]
    #[expected_failure(abort_code = ENftIsNotOwnedByAccount)]
    fun test_call_failure_nft_has_already_been_redeemed(
        aptos_framework: &signer,
        creator: &signer,
        account: &signer,
        receiver: &signer
    ) acquires State, SplitToken {

        let (burn_cap, mint_cap) = aptos_coin::initialize_for_test(aptos_framework);

        let creator_address = signer::address_of(creator);
        let account_address = signer::address_of(account);
        let receiver_address = signer::address_of(receiver);
        account::create_account_for_test(creator_address);
        account::create_account_for_test(account_address);
        account::create_account_for_test(receiver_address);

        coin::register<AptosCoin>(creator);
        coin::register<AptosCoin>(account);
        coin::register<AptosCoin>(receiver);

        init_module(creator);

        let nf_token_collection_name = b"collection1";
        let nf_token_name = b"token1";

        create_nft_collection(account, nf_token_collection_name);
        let nf_token_object = mint_nft_1(account, nf_token_collection_name, nf_token_name);
        let nf_token_address = object::object_address<TestToken1>(&nf_token_object);

        let expected_split_token_name = b"split token";
        let expected_split_token_symbol = b"SPLIT";
        let expected_split_token_description = b"split token desc";
        let expected_split_token_call_threshold = 900_0000_0000;
        let expected_split_token_call_price = 1_0000_0000;
        let expected_split_token_supply = 1000_0000_0000;
        let expected_split_token_icon_uri = b"icon uri";
        let expected_split_token_project_uri = b"project uri";
        split<TestToken1>(
            account,
            nf_token_address,
            string::utf8(expected_split_token_name),
            string::utf8(expected_split_token_symbol),
            string::utf8(expected_split_token_description),
            expected_split_token_supply,
            expected_split_token_call_threshold,
            expected_split_token_call_price,
            string::utf8(expected_split_token_icon_uri),
            string::utf8(expected_split_token_project_uri)
        );

        let state = borrow_global<State>(creator_address);
        let resource_account_signer_cap_ref = &state.signer_capability;
        let resource_account_address = account::get_signer_capability_address(resource_account_signer_cap_ref);

        let split_token_object = object::address_to_object<SplitToken>(split_token_address(expected_split_token_name));

        assert!(split_balance(account_address, split_token_object) == expected_split_token_supply, 0);
        assert!(split_balance(creator_address, split_token_object) == 0, 0);

        assert!(object::owner(nf_token_object) == resource_account_address, 0);

        let transfer_amount = 5_0000_0000;
        primary_fungible_store::transfer<SplitToken>(account, split_token_object, receiver_address, transfer_amount);
        assert!(split_balance(account_address, split_token_object) == expected_split_token_supply - transfer_amount, 0);
        assert!(split_balance(receiver_address, split_token_object) == transfer_amount, 0);

        let expected_aptos_call_payment = expected_split_token_call_price * transfer_amount;
        let coins = coin::mint(expected_aptos_call_payment, &mint_cap);
        coin::deposit(account_address, coins);

        call<TestToken1>(account, split_token_address(expected_split_token_name));

        call<TestToken1>(receiver, split_token_address(expected_split_token_name));

        coin::destroy_burn_cap(burn_cap);
        coin::destroy_mint_cap(mint_cap);
    }

    #[test(aptos_framework = @0x1, creator = @overmind, account = @0xA, receiver = @0xB)]
    fun test_exchange_split_tokens_for_call_payment_success_total_remaining_balance(
        aptos_framework: &signer,
        creator: &signer,
        account: &signer,
        receiver: &signer
    ) acquires State, SplitToken {

        let (burn_cap, mint_cap) = aptos_coin::initialize_for_test(aptos_framework);

        let creator_address = signer::address_of(creator);
        let account_address = signer::address_of(account);
        let receiver_address = signer::address_of(receiver);
        account::create_account_for_test(creator_address);
        account::create_account_for_test(account_address);
        account::create_account_for_test(receiver_address);

        coin::register<AptosCoin>(creator);
        coin::register<AptosCoin>(account);
        coin::register<AptosCoin>(receiver);

        init_module(creator);

        let nf_token_collection_name = b"collection1";
        let nf_token_name = b"token1";

        create_nft_collection(account, nf_token_collection_name);
        let nf_token_object = mint_nft_1(account, nf_token_collection_name, nf_token_name);
        let nf_token_address = object::object_address<TestToken1>(&nf_token_object);

        let expected_split_token_name = b"split token";
        let expected_split_token_symbol = b"SPLIT";
        let expected_split_token_description = b"split token desc";
        let expected_split_token_call_threshold = 900_0000_0000;
        let expected_split_token_call_price = 1_0000_0000;
        let expected_split_token_supply = 1000_0000_0000;
        let expected_split_token_icon_uri = b"icon uri";
        let expected_split_token_project_uri = b"project uri";
        split<TestToken1>(
            account,
            nf_token_address,
            string::utf8(expected_split_token_name),
            string::utf8(expected_split_token_symbol),
            string::utf8(expected_split_token_description),
            expected_split_token_supply,
            expected_split_token_call_threshold,
            expected_split_token_call_price,
            string::utf8(expected_split_token_icon_uri),
            string::utf8(expected_split_token_project_uri)
        );

        let state = borrow_global<State>(creator_address);
        let resource_account_signer_cap_ref = &state.signer_capability;
        let resource_account_address = account::get_signer_capability_address(resource_account_signer_cap_ref);

        let split_token_object = object::address_to_object<SplitToken>(split_token_address(expected_split_token_name));

        assert!(split_balance(account_address, split_token_object) == expected_split_token_supply, 0);
        assert!(split_balance(creator_address, split_token_object) == 0, 0);

        assert!(object::owner(nf_token_object) == resource_account_address, 0);

        let transfer_amount = 50_0000_0000;
        primary_fungible_store::transfer<SplitToken>(account, split_token_object, receiver_address, transfer_amount);
        assert!(split_balance(account_address, split_token_object) == expected_split_token_supply - transfer_amount, 0);
        assert!(split_balance(receiver_address, split_token_object) == transfer_amount, 0);

        let expected_aptos_call_payment = expected_split_token_call_price * transfer_amount;
        let coins = coin::mint(expected_aptos_call_payment, &mint_cap);
        coin::deposit(account_address, coins);

        call<TestToken1>(account, split_token_address(expected_split_token_name));

        assert!(split_balance(account_address, split_token_object) == 0, 0);
        assert!(split_balance(receiver_address, split_token_object) == transfer_amount, 0);

        assert!(coin::balance<AptosCoin>(account_address) == 0, 0);
        assert!(coin::balance<AptosCoin>(resource_account_address) == expected_aptos_call_payment, 0);
        assert!(coin::balance<AptosCoin>(receiver_address) == 0, 0);

        assert!(object::owner(nf_token_object) == account_address, 0);

        exchange_split_tokens_for_call_payment<TestToken1>(receiver, split_token_address(expected_split_token_name));

        assert!(coin::balance<AptosCoin>(account_address) == 0, 0);
        assert!(coin::balance<AptosCoin>(resource_account_address) == 0, 0);
        assert!(coin::balance<AptosCoin>(receiver_address) == expected_aptos_call_payment, 0);

        assert!(split_balance(account_address, split_token_object) == 0, 0);
        assert!(split_balance(receiver_address, split_token_object) == 0, 0);

        assert!(object::owner(nf_token_object) == account_address, 0);

        coin::destroy_burn_cap(burn_cap);
        coin::destroy_mint_cap(mint_cap);

        let split_event_count = get_split_events_count();
        assert!(split_event_count == 1, EWrongNumberOfEventsEmitted);
        let redeem_event_count = get_redeem_events_count();
        assert!(redeem_event_count == 0, EWrongNumberOfEventsEmitted);
        let call_event_count = get_call_events_count();
        assert!(call_event_count == 1, EWrongNumberOfEventsEmitted);
        let exchange_event_count = get_exchange_events_count();
        assert!(exchange_event_count == 1, EWrongNumberOfEventsEmitted);
    }

    #[test(aptos_framework = @0x1, creator = @overmind, account = @0xA, receiver = @0xB)]
    #[expected_failure(abort_code = ENftIsOwnedByAccount)]
    fun test_exchange_split_tokens_for_call_payment_failure_nft_has_not_been_redeemed(
        aptos_framework: &signer,
        creator: &signer,
        account: &signer,
        receiver: &signer
    ) acquires State, SplitToken {

        let (burn_cap, mint_cap) = aptos_coin::initialize_for_test(aptos_framework);

        let creator_address = signer::address_of(creator);
        let account_address = signer::address_of(account);
        let receiver_address = signer::address_of(receiver);
        account::create_account_for_test(creator_address);
        account::create_account_for_test(account_address);
        account::create_account_for_test(receiver_address);

        coin::register<AptosCoin>(creator);
        coin::register<AptosCoin>(account);
        coin::register<AptosCoin>(receiver);

        init_module(creator);

        let nf_token_collection_name = b"collection1";
        let nf_token_name = b"token1";

        create_nft_collection(account, nf_token_collection_name);
        let nf_token_object = mint_nft_1(account, nf_token_collection_name, nf_token_name);
        let nf_token_address = object::object_address<TestToken1>(&nf_token_object);

        let expected_split_token_name = b"split token";
        let expected_split_token_symbol = b"SPLIT";
        let expected_split_token_description = b"split token desc";
        let expected_split_token_call_threshold = 900_0000_0000;
        let expected_split_token_call_price = 1_0000_0000;
        let expected_split_token_supply = 1000_0000_0000;
        let expected_split_token_icon_uri = b"icon uri";
        let expected_split_token_project_uri = b"project uri";
        split<TestToken1>(
            account,
            nf_token_address,
            string::utf8(expected_split_token_name),
            string::utf8(expected_split_token_symbol),
            string::utf8(expected_split_token_description),
            expected_split_token_supply,
            expected_split_token_call_threshold,
            expected_split_token_call_price,
            string::utf8(expected_split_token_icon_uri),
            string::utf8(expected_split_token_project_uri)
        );

        let state = borrow_global<State>(creator_address);
        let resource_account_signer_cap_ref = &state.signer_capability;
        let resource_account_address = account::get_signer_capability_address(resource_account_signer_cap_ref);

        let split_token_object = object::address_to_object<SplitToken>(split_token_address(expected_split_token_name));

        assert!(split_balance(account_address, split_token_object) == expected_split_token_supply, 0);
        assert!(split_balance(creator_address, split_token_object) == 0, 0);

        assert!(object::owner(nf_token_object) == resource_account_address, 0);

        let transfer_amount = 50_0000_0000;
        primary_fungible_store::transfer<SplitToken>(account, split_token_object, receiver_address, transfer_amount);
        assert!(split_balance(account_address, split_token_object) == expected_split_token_supply - transfer_amount, 0);
        assert!(split_balance(receiver_address, split_token_object) == transfer_amount, 0);

        let expected_aptos_call_payment = expected_split_token_call_price * transfer_amount;
        let coins = coin::mint(expected_aptos_call_payment, &mint_cap);
        coin::deposit(account_address, coins);

        exchange_split_tokens_for_call_payment<TestToken1>(receiver, split_token_address(expected_split_token_name));

        coin::destroy_burn_cap(burn_cap);
        coin::destroy_mint_cap(mint_cap);

    }

    #[test(aptos_framework = @0x1, creator = @overmind, account = @0xA, receiver = @0xB)]
    #[expected_failure(abort_code = ESplitTokenBalanceIsZero)]
    fun test_exchange_split_tokens_for_call_payment_failure_zero_split_token_balance(
        aptos_framework: &signer,
        creator: &signer,
        account: &signer,
        receiver: &signer
    ) acquires State, SplitToken {

        let (burn_cap, mint_cap) = aptos_coin::initialize_for_test(aptos_framework);

        let creator_address = signer::address_of(creator);
        let account_address = signer::address_of(account);
        let receiver_address = signer::address_of(receiver);
        account::create_account_for_test(creator_address);
        account::create_account_for_test(account_address);
        account::create_account_for_test(receiver_address);

        coin::register<AptosCoin>(creator);
        coin::register<AptosCoin>(account);
        coin::register<AptosCoin>(receiver);

        init_module(creator);

        let nf_token_collection_name = b"collection1";
        let nf_token_name = b"token1";

        create_nft_collection(account, nf_token_collection_name);
        let nf_token_object = mint_nft_1(account, nf_token_collection_name, nf_token_name);
        let nf_token_address = object::object_address<TestToken1>(&nf_token_object);

        let expected_split_token_name = b"split token";
        let expected_split_token_symbol = b"SPLIT";
        let expected_split_token_description = b"split token desc";
        let expected_split_token_call_threshold = 900_0000_0000;
        let expected_split_token_call_price = 1_0000_0000;
        let expected_split_token_supply = 1000_0000_0000;
        let expected_split_token_icon_uri = b"icon uri";
        let expected_split_token_project_uri = b"project uri";
        split<TestToken1>(
            account,
            nf_token_address,
            string::utf8(expected_split_token_name),
            string::utf8(expected_split_token_symbol),
            string::utf8(expected_split_token_description),
            expected_split_token_supply,
            expected_split_token_call_threshold,
            expected_split_token_call_price,
            string::utf8(expected_split_token_icon_uri),
            string::utf8(expected_split_token_project_uri)
        );

        let state = borrow_global<State>(creator_address);
        let resource_account_signer_cap_ref = &state.signer_capability;
        let resource_account_address = account::get_signer_capability_address(resource_account_signer_cap_ref);

        let split_token_object = object::address_to_object<SplitToken>(split_token_address(expected_split_token_name));

        assert!(split_balance(account_address, split_token_object) == expected_split_token_supply, 0);
        assert!(split_balance(creator_address, split_token_object) == 0, 0);

        assert!(object::owner(nf_token_object) == resource_account_address, 0);

        call<TestToken1>(account, split_token_address(expected_split_token_name));

        exchange_split_tokens_for_call_payment<TestToken1>(receiver, split_token_address(expected_split_token_name));

        coin::destroy_burn_cap(burn_cap);
        coin::destroy_mint_cap(mint_cap);

    }

    #[test_only]
    fun create_nft_collection(
        creator: &signer,
        name: vector<u8>
    ) {
        aptos_token::create_collection(
            creator,
            string::utf8(b""),
            500,
            string::utf8(name),
            string::utf8(b""),
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            0,
            1
        );
    }

    #[test_only]
    fun mint_nft_1(
        creator: &signer,
        collection_name: vector<u8>,
        token_name: vector<u8>
    ): Object<TestToken1> {
        let constructor_ref = token::create_named_token(
            creator,
            string::utf8(collection_name),
            string::utf8(b""),
            string::utf8(token_name),
            option::some<royalty::Royalty>(
                royalty::create(0, 1, signer::address_of(creator))
            ),
            string::utf8(b"")
        );
        let token_signer = object::generate_signer(&constructor_ref);

        let token = TestToken1{};

        move_to(&token_signer, token);

        object::address_to_object(signer::address_of(&token_signer))
    }

    #[test_only]
    fun mint_nft_2(
        creator: &signer,
        collection_name: vector<u8>,
        token_name: vector<u8>
    ): Object<TestToken2> {
        let constructor_ref = token::create_named_token(
            creator,
            string::utf8(collection_name),
            string::utf8(b""),
            string::utf8(token_name),
            option::some<royalty::Royalty>(
                royalty::create(0, 1, signer::address_of(creator))
            ),
            string::utf8(b"")
        );
        let token_signer = object::generate_signer(&constructor_ref);

        let token = TestToken2{};

        move_to(&token_signer, token);

        object::address_to_object(signer::address_of(&token_signer))
    }

    #[test_only]
    fun split_token_address(split_token_name: vector<u8>): address acquires State {

        // TODO: Generate the split token address with the provided token name
        let state = borrow_global_mut<State>(@overmind);
        let resource_account_signer_cap = &state.signer_capability;
        let resource_account_address = account::get_signer_capability_address(resource_account_signer_cap);

        token::create_token_address(
            &resource_account_address,
            &string::utf8(SPLIT_COLLECTION_NAME),
            &string::utf8(split_token_name)
        )
    }

    #[test_only]
    fun get_split_events_count(): u64 acquires State {
        let state = borrow_global<State>(@overmind);
        event::counter<SplitEvent>(&state.split_events)
    }

    #[test_only]
    fun get_redeem_events_count(): u64 acquires State {
        let state = borrow_global<State>(@overmind);
        event::counter<RedeemEvent>(&state.redeem_events)
    }

    #[test_only]
    fun get_call_events_count(): u64 acquires State {
        let state = borrow_global<State>(@overmind);
        event::counter<CallEvent>(&state.call_events)
    }

    #[test_only]
    fun get_exchange_events_count(): u64 acquires State {
        let state = borrow_global<State>(@overmind);
        event::counter<ExchangeEvent>(&state.exchange_events)
    }
}