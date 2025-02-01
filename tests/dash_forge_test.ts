import {
    Clarinet,
    Tx,
    Chain,
    Account,
    types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Can create a new dashboard",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet_1 = accounts.get('wallet_1')!;
        const title = "My Dashboard";
        const config = '{"type": "bar-chart", "data": {}}';
        
        let block = chain.mineBlock([
            Tx.contractCall('dash_forge', 'create-dashboard', [
                types.utf8(title),
                types.utf8(config)
            ], wallet_1.address)
        ]);
        
        block.receipts[0].result.expectOk().expectUint(1);
    }
});

Clarinet.test({
    name: "Can convert dashboard to template",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet_1 = accounts.get('wallet_1')!;
        
        // First create a dashboard
        let block = chain.mineBlock([
            Tx.contractCall('dash_forge', 'create-dashboard', [
                types.utf8("Template Dashboard"),
                types.utf8('{"type": "bar-chart"}')
            ], wallet_1.address)
        ]);
        
        // Convert to template
        let templateBlock = chain.mineBlock([
            Tx.contractCall('dash_forge', 'convert-to-template', [
                types.uint(1),
                types.uint(100)
            ], wallet_1.address)
        ]);
        
        templateBlock.receipts[0].result.expectOk().expectBool(true);
    }
});

Clarinet.test({
    name: "Can purchase template",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet_1 = accounts.get('wallet_1')!;
        const wallet_2 = accounts.get('wallet_2')!;
        const price = 100;
        
        // Create and convert to template
        let setup = chain.mineBlock([
            Tx.contractCall('dash_forge', 'create-dashboard', [
                types.utf8("Template Dashboard"),
                types.utf8('{"type": "bar-chart"}')
            ], wallet_1.address),
            Tx.contractCall('dash_forge', 'convert-to-template', [
                types.uint(1),
                types.uint(price)
            ], wallet_1.address)
        ]);
        
        // Purchase template
        let purchaseBlock = chain.mineBlock([
            Tx.contractCall('dash_forge', 'purchase-template', [
                types.uint(1)
            ], wallet_2.address)
        ]);
        
        purchaseBlock.receipts[0].result.expectOk().expectUint(2);
    }
});

Clarinet.test({
    name: "Can update dashboard if owner",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet_1 = accounts.get('wallet_1')!;
        const title = "My Dashboard";
        const config = '{"type": "bar-chart", "data": {}}';
        const newTitle = "Updated Dashboard";
        const newConfig = '{"type": "pie-chart", "data": {}}';
        
        // First create a dashboard
        let block = chain.mineBlock([
            Tx.contractCall('dash_forge', 'create-dashboard', [
                types.utf8(title),
                types.utf8(config)
            ], wallet_1.address)
        ]);
        
        // Then update it
        let updateBlock = chain.mineBlock([
            Tx.contractCall('dash_forge', 'update-dashboard', [
                types.uint(1),
                types.utf8(newTitle),
                types.utf8(newConfig)
            ], wallet_1.address)
        ]);
        
        updateBlock.receipts[0].result.expectOk().expectBool(true);
    }
});

Clarinet.test({
    name: "Can grant and use access rights",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet_1 = accounts.get('wallet_1')!;
        const wallet_2 = accounts.get('wallet_2')!;
        
        // Create dashboard
        let block = chain.mineBlock([
            Tx.contractCall('dash_forge', 'create-dashboard', [
                types.utf8("Shared Dashboard"),
                types.utf8('{"type": "bar-chart"}')
            ], wallet_1.address)
        ]);
        
        // Grant access
        let accessBlock = chain.mineBlock([
            Tx.contractCall('dash_forge', 'grant-access', [
                types.uint(1),
                types.principal(wallet_2.address),
                types.bool(true),
                types.bool(true)
            ], wallet_1.address)
        ]);
        
        // Try to update as wallet_2
        let updateBlock = chain.mineBlock([
            Tx.contractCall('dash_forge', 'update-dashboard', [
                types.uint(1),
                types.utf8("Updated by wallet 2"),
                types.utf8('{"type": "line-chart"}')
            ], wallet_2.address)
        ]);
        
        accessBlock.receipts[0].result.expectOk().expectBool(true);
        updateBlock.receipts[0].result.expectOk().expectBool(true);
    }
});
