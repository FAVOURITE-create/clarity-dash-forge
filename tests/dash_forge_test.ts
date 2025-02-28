[... original test content plus new tests ...]

Clarinet.test({
    name: "Can delete dashboard if owner",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet_1 = accounts.get('wallet_1')!;
        
        // Create dashboard
        let block = chain.mineBlock([
            Tx.contractCall('dash_forge', 'create-dashboard', [
                types.utf8("Test Dashboard"),
                types.utf8('{"type": "bar-chart"}')
            ], wallet_1.address)
        ]);
        
        // Delete dashboard
        let deleteBlock = chain.mineBlock([
            Tx.contractCall('dash_forge', 'delete-dashboard', [
                types.uint(1)
            ], wallet_1.address)
        ]);
        
        deleteBlock.receipts[0].result.expectOk().expectBool(true);
    }
});

[... additional new tests ...]
