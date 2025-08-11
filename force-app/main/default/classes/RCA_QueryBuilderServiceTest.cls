/**
 * @description Test class for RCA_QueryBuilderService
 * @author RCA Development Team
 * @date 2024
 */
@IsTest
public class RCA_QueryBuilderServiceTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test Account
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        // Create test Opportunity
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = testAccount.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Amount = 10000
        );
        insert testOpp;
        
        // Get standard price book
        Id pricebookId = Test.getStandardPricebookId();
        
        // Create test Quotes with Pricebook
        Quote testQuote1 = new Quote(
            Name = 'Test Quote 1',
            OpportunityId = testOpp.Id,
            Pricebook2Id = pricebookId,
            Status = 'Draft',
            ExpirationDate = Date.today().addDays(30)
        );
        
        Quote testQuote2 = new Quote(
            Name = 'Test Quote 2',
            OpportunityId = testOpp.Id,
            Pricebook2Id = pricebookId,
            Status = 'Draft',
            ExpirationDate = Date.today().addDays(30)
        );
        
        insert new List<Quote>{testQuote1, testQuote2};
        
        // Create test Products
        Product2 testProduct = new Product2(
            Name = 'Test Product',
            IsActive = true
        );
        insert testProduct;
        
        // Create price book entry
        PricebookEntry testPBE = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = testProduct.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert testPBE;
        
        // Create Quote Line Items
        QuoteLineItem testQLI1 = new QuoteLineItem(
            QuoteId = testQuote1.Id,
            Product2Id = testProduct.Id,
            PricebookEntryId = testPBE.Id,
            Quantity = 1,
            UnitPrice = 100
        );
        
        QuoteLineItem testQLI2 = new QuoteLineItem(
            QuoteId = testQuote2.Id,
            Product2Id = testProduct.Id,
            PricebookEntryId = testPBE.Id,
            Quantity = 2,
            UnitPrice = 100
        );
        
        insert new List<QuoteLineItem>{testQLI1, testQLI2};
    }
    
    @IsTest
    static void testBuildSOQLQuery() {
        Test.startTest();
        
        // Create test field definitions
        List<RCA_DataStructures.FieldDefinition> fields = new List<RCA_DataStructures.FieldDefinition>();
        
        RCA_DataStructures.FieldDefinition field1 = new RCA_DataStructures.FieldDefinition();
        field1.apiName = 'Name';
        field1.label = 'Name';
        field1.type = 'STRING';
        fields.add(field1);
        
        RCA_DataStructures.FieldDefinition field2 = new RCA_DataStructures.FieldDefinition();
        field2.apiName = 'Status';
        field2.label = 'Status';
        field2.type = 'PICKLIST';
        fields.add(field2);
        
        // Test building SOQL query
        String soql = RCA_QueryBuilderService.buildSOQLQuery('Quote', fields, 'Id != null');
        
        Test.stopTest();
        
        // Verify results
        System.assertNotEquals(null, soql, 'SOQL should not be null');
        System.assert(soql.contains('SELECT'), 'SOQL should contain SELECT');
        System.assert(soql.contains('FROM Quote'), 'SOQL should contain FROM Quote');
        System.assert(soql.contains('WHERE Id != null'), 'SOQL should contain WHERE clause');
        System.assert(soql.contains('Id'), 'SOQL should contain Id field');
        System.assert(soql.contains('Name'), 'SOQL should contain Name field');
        System.assert(soql.contains('Status'), 'SOQL should contain Status field');
    }
    
    @IsTest
    static void testBuildSOQLQueryNoWhereClause() {
        Test.startTest();
        
        // Create test field definitions
        List<RCA_DataStructures.FieldDefinition> fields = new List<RCA_DataStructures.FieldDefinition>();
        
        RCA_DataStructures.FieldDefinition field1 = new RCA_DataStructures.FieldDefinition();
        field1.apiName = 'Name';
        field1.label = 'Name';
        field1.type = 'STRING';
        fields.add(field1);
        
        // Test building SOQL query without WHERE clause
        String soql = RCA_QueryBuilderService.buildSOQLQuery('Quote', fields, '');
        
        Test.stopTest();
        
        // Verify results
        System.assertNotEquals(null, soql, 'SOQL should not be null');
        System.assert(soql.contains('SELECT'), 'SOQL should contain SELECT');
        System.assert(soql.contains('FROM Quote'), 'SOQL should contain FROM Quote');
        System.assert(!soql.contains('WHERE'), 'SOQL should not contain WHERE clause');
    }
    
    @IsTest
    static void testExecuteSelfQuery() {
        // Get test data
        List<Quote> testQuotes = [SELECT Id FROM Quote LIMIT 2];
        
        // Create mock configuration object
        RCA_Comparison_Object__mdt configObj = new RCA_Comparison_Object__mdt();
        configObj.Object_API_Name__c = 'Quote';
        configObj.Relationship_Type__c = 'Self';
        
        // Create test field definitions
        List<RCA_DataStructures.FieldDefinition> fields = new List<RCA_DataStructures.FieldDefinition>();
        RCA_DataStructures.FieldDefinition field1 = new RCA_DataStructures.FieldDefinition();
        field1.apiName = 'Name';
        field1.label = 'Name';
        field1.type = 'STRING';
        fields.add(field1);
        
        Test.startTest();
        
        // Test executing self query
        RCA_DataStructures.QueryResult result = RCA_QueryBuilderService.executeSelfQuery(
            configObj, testQuotes[0].Id, testQuotes[1].Id, fields
        );
        
        Test.stopTest();
        
        // Verify results
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals('Quote', result.objectApiName, 'Object API name should match');
        System.assertEquals('Self', result.relationshipType, 'Relationship type should match');
        System.assertNotEquals(null, result.records, 'Records should not be null');
        System.assertEquals(2, result.records.size(), 'Should return 2 quote records');
    }
    
    @IsTest
    static void testExecuteParentQuery() {
        // Get test data
        List<Quote> testQuotes = [SELECT Id, OpportunityId FROM Quote LIMIT 2];
        
        // Create mock configuration object
        RCA_Comparison_Object__mdt configObj = new RCA_Comparison_Object__mdt();
        configObj.Object_API_Name__c = 'Opportunity';
        configObj.Relationship_Type__c = 'Parent';
        configObj.Relationship_Name__c = 'OpportunityId';
        
        // Create test field definitions
        List<RCA_DataStructures.FieldDefinition> fields = new List<RCA_DataStructures.FieldDefinition>();
        RCA_DataStructures.FieldDefinition field1 = new RCA_DataStructures.FieldDefinition();
        field1.apiName = 'Name';
        field1.label = 'Name';
        field1.type = 'STRING';
        fields.add(field1);
        
        Test.startTest();
        
        // Test executing parent query
        RCA_DataStructures.QueryResult result = RCA_QueryBuilderService.executeParentQuery(
            configObj, testQuotes[0].Id, testQuotes[1].Id, fields
        );
        
        Test.stopTest();
        
        // Verify results
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals('Opportunity', result.objectApiName, 'Object API name should match');
        System.assertEquals('Parent', result.relationshipType, 'Relationship type should match');
        System.assertNotEquals(null, result.records, 'Records should not be null');
    }
    
    @IsTest
    static void testExecuteChildQuery() {
        // Get test data
        List<Quote> testQuotes = [SELECT Id FROM Quote LIMIT 2];
        
        // Create mock configuration object
        RCA_Comparison_Object__mdt configObj = new RCA_Comparison_Object__mdt();
        configObj.Object_API_Name__c = 'QuoteLineItem';
        configObj.Relationship_Type__c = 'Child';
        
        // Create test field definitions
        List<RCA_DataStructures.FieldDefinition> fields = new List<RCA_DataStructures.FieldDefinition>();
        RCA_DataStructures.FieldDefinition field1 = new RCA_DataStructures.FieldDefinition();
        field1.apiName = 'Quantity';
        field1.label = 'Quantity';
        field1.type = 'DOUBLE';
        fields.add(field1);
        
        Test.startTest();
        
        // Test executing child query
        RCA_DataStructures.QueryResult result = RCA_QueryBuilderService.executeChildQuery(
            configObj, testQuotes[0].Id, testQuotes[1].Id, fields
        );
        
        Test.stopTest();
        
        // Verify results
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals('QuoteLineItem', result.objectApiName, 'Object API name should match');
        System.assertEquals('Child', result.relationshipType, 'Relationship type should match');
        System.assertNotEquals(null, result.records, 'Records should not be null');
    }
    
    @IsTest
    static void testExecuteChildQueryWithParentIdentifier() {
        // Get test data
        List<Quote> testQuotes = [SELECT Id FROM Quote LIMIT 2];
        
        // Create mock configuration object for grandchild relationship
        RCA_Comparison_Object__mdt configObj = new RCA_Comparison_Object__mdt();
        configObj.Object_API_Name__c = 'QuoteLineItem'; // Using QLI as example
        configObj.Relationship_Type__c = 'Child';
        configObj.Parent_Identifier_Field__c = 'QuoteId'; // This would normally be for grandchild objects
        
        // Create test field definitions
        List<RCA_DataStructures.FieldDefinition> fields = new List<RCA_DataStructures.FieldDefinition>();
        RCA_DataStructures.FieldDefinition field1 = new RCA_DataStructures.FieldDefinition();
        field1.apiName = 'Quantity';
        field1.label = 'Quantity';
        field1.type = 'DOUBLE';
        fields.add(field1);
        
        Test.startTest();
        
        // Test executing child query with parent identifier
        RCA_DataStructures.QueryResult result = RCA_QueryBuilderService.executeChildQuery(
            configObj, testQuotes[0].Id, testQuotes[1].Id, fields
        );
        
        Test.stopTest();
        
        // Verify results
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals('QuoteLineItem', result.objectApiName, 'Object API name should match');
        System.assertEquals('Child', result.relationshipType, 'Relationship type should match');
        System.assertNotEquals(null, result.records, 'Records should not be null');
    }
    
    @IsTest
    static void testGetParentLineItems() {
        // Get test data
        List<Quote> testQuotes = [SELECT Id FROM Quote LIMIT 2];
        
        Test.startTest();
        
        // Test getting parent line items
        List<QuoteLineItem> lineItems = RCA_QueryBuilderService.getParentLineItems(
            testQuotes[0].Id, testQuotes[1].Id
        );
        
        Test.stopTest();
        
        // Verify results
        System.assertNotEquals(null, lineItems, 'Line items should not be null');
        System.assertEquals(2, lineItems.size(), 'Should return 2 line items');
    }
    
    @IsTest
    static void testExecuteQuerySelf() {
        // Get test data
        List<Quote> testQuotes = [SELECT Id FROM Quote LIMIT 2];
        
        // Create mock configuration object
        RCA_Comparison_Object__mdt configObj = new RCA_Comparison_Object__mdt();
        configObj.Object_API_Name__c = 'Quote';
        configObj.Relationship_Type__c = 'Self';
        
        // Create test field definitions
        List<RCA_DataStructures.FieldDefinition> fields = new List<RCA_DataStructures.FieldDefinition>();
        RCA_DataStructures.FieldDefinition field1 = new RCA_DataStructures.FieldDefinition();
        field1.apiName = 'Name';
        field1.label = 'Name';
        field1.type = 'STRING';
        fields.add(field1);
        
        Test.startTest();
        
        // Test executing query with Self relationship
        RCA_DataStructures.QueryResult result = RCA_QueryBuilderService.executeQuery(
            configObj, testQuotes[0].Id, testQuotes[1].Id, fields
        );
        
        Test.stopTest();
        
        // Verify results
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals('Self', result.relationshipType, 'Should handle Self relationship');
    }
    
    @IsTest
    static void testExecuteQueryParent() {
        // Get test data
        List<Quote> testQuotes = [SELECT Id FROM Quote LIMIT 2];
        
        // Create mock configuration object
        RCA_Comparison_Object__mdt configObj = new RCA_Comparison_Object__mdt();
        configObj.Object_API_Name__c = 'Opportunity';
        configObj.Relationship_Type__c = 'Parent';
        configObj.Relationship_Name__c = 'OpportunityId';
        
        // Create test field definitions
        List<RCA_DataStructures.FieldDefinition> fields = new List<RCA_DataStructures.FieldDefinition>();
        RCA_DataStructures.FieldDefinition field1 = new RCA_DataStructures.FieldDefinition();
        field1.apiName = 'Name';
        field1.label = 'Name';
        field1.type = 'STRING';
        fields.add(field1);
        
        Test.startTest();
        
        // Test executing query with Parent relationship
        RCA_DataStructures.QueryResult result = RCA_QueryBuilderService.executeQuery(
            configObj, testQuotes[0].Id, testQuotes[1].Id, fields
        );
        
        Test.stopTest();
        
        // Verify results
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals('Parent', result.relationshipType, 'Should handle Parent relationship');
    }
    
    @IsTest
    static void testExecuteQueryChild() {
        // Get test data
        List<Quote> testQuotes = [SELECT Id FROM Quote LIMIT 2];
        
        // Create mock configuration object
        RCA_Comparison_Object__mdt configObj = new RCA_Comparison_Object__mdt();
        configObj.Object_API_Name__c = 'QuoteLineItem';
        configObj.Relationship_Type__c = 'Child';
        
        // Create test field definitions
        List<RCA_DataStructures.FieldDefinition> fields = new List<RCA_DataStructures.FieldDefinition>();
        RCA_DataStructures.FieldDefinition field1 = new RCA_DataStructures.FieldDefinition();
        field1.apiName = 'Quantity';
        field1.label = 'Quantity';
        field1.type = 'DOUBLE';
        fields.add(field1);
        
        Test.startTest();
        
        // Test executing query with Child relationship
        RCA_DataStructures.QueryResult result = RCA_QueryBuilderService.executeQuery(
            configObj, testQuotes[0].Id, testQuotes[1].Id, fields
        );
        
        Test.stopTest();
        
        // Verify results
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals('Child', result.relationshipType, 'Should handle Child relationship');
    }
    
    @IsTest
    static void testExecuteQueryUnsupportedRelationship() {
        // Get test data
        List<Quote> testQuotes = [SELECT Id FROM Quote LIMIT 2];
        
        // Create mock configuration object with unsupported relationship
        RCA_Comparison_Object__mdt configObj = new RCA_Comparison_Object__mdt();
        configObj.Object_API_Name__c = 'Quote';
        configObj.Relationship_Type__c = 'Unsupported';
        
        // Create test field definitions
        List<RCA_DataStructures.FieldDefinition> fields = new List<RCA_DataStructures.FieldDefinition>();
        
        Test.startTest();
        
        try {
            // Test executing query with unsupported relationship
            RCA_DataStructures.QueryResult result = RCA_QueryBuilderService.executeQuery(
                configObj, testQuotes[0].Id, testQuotes[1].Id, fields
            );
            System.assert(false, 'Should have thrown exception for unsupported relationship');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Unsupported relationship type'), 'Should throw appropriate exception');
        }
        
        Test.stopTest();
    }
}
