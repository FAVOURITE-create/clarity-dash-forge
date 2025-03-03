[... previous tests ...]

Clarinet.test({
    name: "Version rollback properly stores new version",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet_1 = accounts.get('wallet_1')!;
        
        // Create dashboard
        let block = chain.mineBlock([
            Tx.contractCall('dash_forge', 'create-dashboard', [
                types.utf8("Test Dashboard"),
                types.utf8('{"version": "1"}')
            ], wallet_1.address)
        ]);
        
        // Update dashboard to create version 2
        block = chain.mineBlock([
            Tx.contractCall('dash_forge', 'update-dashboard', [
                types.uint(1),
                types.utf8("Test Dashboard"),
                types.utf8('{"version": "2"}')
            ], wallet_1.address)
        ]);
        
        // Rollback to version 1
        let rollbackBlock = chain.mineBlock([
            Tx.contractCall('dash_forge', 'rollback-version', [
                types.uint(1),
                types.uint(1)
            ], wallet_1.address)
        ]);
        
        rollbackBlock.receipts[0].result.expectOk().expectBool(true);
        
        // Verify new version is created
        let dashboard = chain.callReadOnlyFn(
            'dash_forge',
            'get-dashboard',
            [types.uint(1)],
            wallet_1.address
        ).result.expectSome().expectTuple();
        
        assertEquals(dashboard['version'], types.uint(3));
    }
});

[... remaining original tests ...]
