/**
 * @description Test class for RCA_DataProcessorService
 * @author RCA Development Team
 * @date 2024
 */
@IsTest
public class RCA_DataProcessorServiceTest {
    
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
    static void testProcessSelfResults() {
        // Get test data
        List<Quote> testQuotes = [SELECT Id, Name FROM Quote];
        
        // Create query result
        RCA_DataStructures.QueryResult queryResult = new RCA_DataStructures.QueryResult(
            testQuotes, 'Quote', 'Self'
        );
        
        // Create mock configuration object
        RCA_Comparison_Object__mdt configObj = new RCA_Comparison_Object__mdt();
        configObj.Label = 'Quote';
        configObj.Object_API_Name__c = 'Quote';
        
        // Create field definitions
        List<RCA_DataStructures.FieldDefinition> fieldDefinitions = new List<RCA_DataStructures.FieldDefinition>();
        RCA_DataStructures.FieldDefinition field = new RCA_DataStructures.FieldDefinition();
        field.apiName = 'Name';
        field.label = 'Name';
        field.type = 'STRING';
        fieldDefinitions.add(field);
        
        // Create payload
        RCA_DataStructures.ComparisonPayload payload = new RCA_DataStructures.ComparisonPayload();
        
        Test.startTest();
        
        // Test processing self results
        RCA_DataProcessorService.processSelfResults(
            queryResult, configObj, testQuotes[0].Id, testQuotes[1].Id, fieldDefinitions, payload
        );
        
        Test.stopTest();
        
        // Verify results
        System.assert(payload.quote1Data.containsKey('Quote'), 'Should contain Quote data for quote 1');
        System.assert(payload.quote2Data.containsKey('Quote'), 'Should contain Quote data for quote 2');
        
        RCA_DataStructures.ObjectSection quote1Section = payload.quote1Data.get('Quote');
        RCA_DataStructures.ObjectSection quote2Section = payload.quote2Data.get('Quote');
        
        System.assertEquals('Quote', quote1Section.objectLabel, 'Quote 1 section should have correct label');
        System.assertEquals('Quote', quote2Section.objectLabel, 'Quote 2 section should have correct label');
        System.assertNotEquals(null, quote1Section.record, 'Quote 1 section should have record');
        System.assertNotEquals(null, quote2Section.record, 'Quote 2 section should have record');
    }
    
    @IsTest
    static void testProcessParentResults() {
        // Get test data
        List<Quote> testQuotes = [SELECT Id, OpportunityId FROM Quote];
        List<Opportunity> testOpps = [SELECT Id, Name FROM Opportunity];
        
        // Create query result
        RCA_DataStructures.QueryResult queryResult = new RCA_DataStructures.QueryResult(
            testOpps, 'Opportunity', 'Parent'
        );
        
        // Create mock configuration object
        RCA_Comparison_Object__mdt configObj = new RCA_Comparison_Object__mdt();
        configObj.Label = 'Opportunity';
        configObj.Object_API_Name__c = 'Opportunity';
        configObj.Relationship_Name__c = 'OpportunityId';
        
        // Create field definitions
        List<RCA_DataStructures.FieldDefinition> fieldDefinitions = new List<RCA_DataStructures.FieldDefinition>();
        RCA_DataStructures.FieldDefinition field = new RCA_DataStructures.FieldDefinition();
        field.apiName = 'Name';
        field.label = 'Name';
        field.type = 'STRING';
        fieldDefinitions.add(field);
        
        // Create payload
        RCA_DataStructures.ComparisonPayload payload = new RCA_DataStructures.ComparisonPayload();
        
        Test.startTest();
        
        // Test processing parent results
        RCA_DataProcessorService.processParentResults(
            queryResult, configObj, testQuotes[0].Id, testQuotes[1].Id, fieldDefinitions, payload
        );
        
        Test.stopTest();
        
        // Verify results
        System.assert(payload.quote1Data.containsKey('Opportunity'), 'Should contain Opportunity data for quote 1');
        System.assert(payload.quote2Data.containsKey('Opportunity'), 'Should contain Opportunity data for quote 2');
        
        RCA_DataStructures.ObjectSection quote1Section = payload.quote1Data.get('Opportunity');
        RCA_DataStructures.ObjectSection quote2Section = payload.quote2Data.get('Opportunity');
        
        System.assertEquals('Opportunity', quote1Section.objectLabel, 'Quote 1 section should have correct label');
        System.assertEquals('Opportunity', quote2Section.objectLabel, 'Quote 2 section should have correct label');
    }
    
    @IsTest
    static void testProcessChildResults() {
        // Get test data
        List<Quote> testQuotes = [SELECT Id FROM Quote];
        List<QuoteLineItem> testQLIs = [SELECT Id, QuoteId, Quantity FROM QuoteLineItem];
        
        // Create query result
        RCA_DataStructures.QueryResult queryResult = new RCA_DataStructures.QueryResult(
            testQLIs, 'QuoteLineItem', 'Child'
        );
        
        // Create mock configuration object
        RCA_Comparison_Object__mdt configObj = new RCA_Comparison_Object__mdt();
        configObj.Label = 'Quote Line Items';
        configObj.Object_API_Name__c = 'QuoteLineItem';
        // No Parent_Identifier_Field__c for direct child
        
        // Create field definitions
        List<RCA_DataStructures.FieldDefinition> fieldDefinitions = new List<RCA_DataStructures.FieldDefinition>();
        RCA_DataStructures.FieldDefinition field = new RCA_DataStructures.FieldDefinition();
        field.apiName = 'Quantity';
        field.label = 'Quantity';
        field.type = 'DOUBLE';
        fieldDefinitions.add(field);
        
        // Create payload
        RCA_DataStructures.ComparisonPayload payload = new RCA_DataStructures.ComparisonPayload();
        
        Test.startTest();
        
        // Test processing child results
        RCA_DataProcessorService.processChildResults(
            queryResult, configObj, testQuotes[0].Id, testQuotes[1].Id, fieldDefinitions, payload
        );
        
        Test.stopTest();
        
        // Verify results
        System.assert(payload.quote1Data.containsKey('QuoteLineItem'), 'Should contain QuoteLineItem data for quote 1');
        System.assert(payload.quote2Data.containsKey('QuoteLineItem'), 'Should contain QuoteLineItem data for quote 2');
        
        RCA_DataStructures.ObjectSection quote1Section = payload.quote1Data.get('QuoteLineItem');
        RCA_DataStructures.ObjectSection quote2Section = payload.quote2Data.get('QuoteLineItem');
        
        System.assertEquals('Quote Line Items', quote1Section.objectLabel, 'Quote 1 section should have correct label');
        System.assertEquals('Quote Line Items', quote2Section.objectLabel, 'Quote 2 section should have correct label');
        System.assertNotEquals(null, quote1Section.childRecords, 'Quote 1 section should have child records');
        System.assertNotEquals(null, quote2Section.childRecords, 'Quote 2 section should have child records');
    }
    
    @IsTest
    static void testProcessChildResultsWithGrandchildren() {
        // Get test data
        List<Quote> testQuotes = [SELECT Id FROM Quote];
        List<QuoteLineItem> testQLIs = [SELECT Id, QuoteId, Quantity FROM QuoteLineItem];
        
        // Create query result (simulating grandchild records)
        RCA_DataStructures.QueryResult queryResult = new RCA_DataStructures.QueryResult(
            testQLIs, 'QuoteLineItem', 'Child'
        );
        
        // Create mock configuration object with parent identifier (grandchild scenario)
        RCA_Comparison_Object__mdt configObj = new RCA_Comparison_Object__mdt();
        configObj.Label = 'Line Attributes';
        configObj.Object_API_Name__c = 'QuoteLineItem';
        configObj.Parent_Identifier_Field__c = 'QuoteId'; // Simulating grandchild relationship
        
        // Create field definitions
        List<RCA_DataStructures.FieldDefinition> fieldDefinitions = new List<RCA_DataStructures.FieldDefinition>();
        RCA_DataStructures.FieldDefinition field = new RCA_DataStructures.FieldDefinition();
        field.apiName = 'Quantity';
        field.label = 'Quantity';
        field.type = 'DOUBLE';
        fieldDefinitions.add(field);
        
        // Create payload
        RCA_DataStructures.ComparisonPayload payload = new RCA_DataStructures.ComparisonPayload();
        
        Test.startTest();
        
        // Test processing child results with grandchildren
        RCA_DataProcessorService.processChildResults(
            queryResult, configObj, testQuotes[0].Id, testQuotes[1].Id, fieldDefinitions, payload
        );
        
        Test.stopTest();
        
        // Verify results
        System.assert(payload.quote1Data.containsKey('QuoteLineItem'), 'Should contain data for quote 1');
        System.assert(payload.quote2Data.containsKey('QuoteLineItem'), 'Should contain data for quote 2');
        
        RCA_DataStructures.ObjectSection quote1Section = payload.quote1Data.get('QuoteLineItem');
        RCA_DataStructures.ObjectSection quote2Section = payload.quote2Data.get('QuoteLineItem');
        
        System.assertEquals('Line Attributes', quote1Section.objectLabel, 'Quote 1 section should have correct label');
        System.assertEquals('Line Attributes', quote2Section.objectLabel, 'Quote 2 section should have correct label');
    }
    
    @IsTest
    static void testProcessQueryResultSelf() {
        // Get test data
        List<Quote> testQuotes = [SELECT Id, Name FROM Quote];
        
        // Create query result
        RCA_DataStructures.QueryResult queryResult = new RCA_DataStructures.QueryResult(
            testQuotes, 'Quote', 'Self'
        );
        
        // Create mock configuration object
        RCA_Comparison_Object__mdt configObj = new RCA_Comparison_Object__mdt();
        configObj.Label = 'Quote';
        configObj.Object_API_Name__c = 'Quote';
        
        // Create field definitions
        List<RCA_DataStructures.FieldDefinition> fieldDefinitions = new List<RCA_DataStructures.FieldDefinition>();
        RCA_DataStructures.FieldDefinition field = new RCA_DataStructures.FieldDefinition();
        field.apiName = 'Name';
        field.label = 'Name';
        field.type = 'STRING';
        fieldDefinitions.add(field);
        
        // Create payload
        RCA_DataStructures.ComparisonPayload payload = new RCA_DataStructures.ComparisonPayload();
        
        Test.startTest();
        
        // Test processing query result with Self relationship
        RCA_DataProcessorService.processQueryResult(
            queryResult, configObj, testQuotes[0].Id, testQuotes[1].Id, fieldDefinitions, payload
        );
        
        Test.stopTest();
        
        // Verify results
        System.assert(payload.quote1Data.containsKey('Quote'), 'Should process Self relationship');
        System.assert(payload.quote2Data.containsKey('Quote'), 'Should process Self relationship');
    }
    
    @IsTest
    static void testProcessQueryResultParent() {
        // Get test data
        List<Quote> testQuotes = [SELECT Id, OpportunityId FROM Quote];
        List<Opportunity> testOpps = [SELECT Id, Name FROM Opportunity];
        
        // Create query result
        RCA_DataStructures.QueryResult queryResult = new RCA_DataStructures.QueryResult(
            testOpps, 'Opportunity', 'Parent'
        );
        
        // Create mock configuration object
        RCA_Comparison_Object__mdt configObj = new RCA_Comparison_Object__mdt();
        configObj.Label = 'Opportunity';
        configObj.Object_API_Name__c = 'Opportunity';
        configObj.Relationship_Name__c = 'OpportunityId';
        
        // Create field definitions
        List<RCA_DataStructures.FieldDefinition> fieldDefinitions = new List<RCA_DataStructures.FieldDefinition>();
        RCA_DataStructures.FieldDefinition field = new RCA_DataStructures.FieldDefinition();
        field.apiName = 'Name';
        field.label = 'Name';
        field.type = 'STRING';
        fieldDefinitions.add(field);
        
        // Create payload
        RCA_DataStructures.ComparisonPayload payload = new RCA_DataStructures.ComparisonPayload();
        
        Test.startTest();
        
        // Test processing query result with Parent relationship
        RCA_DataProcessorService.processQueryResult(
            queryResult, configObj, testQuotes[0].Id, testQuotes[1].Id, fieldDefinitions, payload
        );
        
        Test.stopTest();
        
        // Verify results
        System.assert(payload.quote1Data.containsKey('Opportunity'), 'Should process Parent relationship');
        System.assert(payload.quote2Data.containsKey('Opportunity'), 'Should process Parent relationship');
    }
    
    @IsTest
    static void testProcessQueryResultChild() {
        // Get test data
        List<Quote> testQuotes = [SELECT Id FROM Quote];
        List<QuoteLineItem> testQLIs = [SELECT Id, QuoteId, Quantity FROM QuoteLineItem];
        
        // Create query result
        RCA_DataStructures.QueryResult queryResult = new RCA_DataStructures.QueryResult(
            testQLIs, 'QuoteLineItem', 'Child'
        );
        
        // Create mock configuration object
        RCA_Comparison_Object__mdt configObj = new RCA_Comparison_Object__mdt();
        configObj.Label = 'Quote Line Items';
        configObj.Object_API_Name__c = 'QuoteLineItem';
        
        // Create field definitions
        List<RCA_DataStructures.FieldDefinition> fieldDefinitions = new List<RCA_DataStructures.FieldDefinition>();
        RCA_DataStructures.FieldDefinition field = new RCA_DataStructures.FieldDefinition();
        field.apiName = 'Quantity';
        field.label = 'Quantity';
        field.type = 'DOUBLE';
        fieldDefinitions.add(field);
        
        // Create payload
        RCA_DataStructures.ComparisonPayload payload = new RCA_DataStructures.ComparisonPayload();
        
        Test.startTest();
        
        // Test processing query result with Child relationship
        RCA_DataProcessorService.processQueryResult(
            queryResult, configObj, testQuotes[0].Id, testQuotes[1].Id, fieldDefinitions, payload
        );
        
        Test.stopTest();
        
        // Verify results
        System.assert(payload.quote1Data.containsKey('QuoteLineItem'), 'Should process Child relationship');
        System.assert(payload.quote2Data.containsKey('QuoteLineItem'), 'Should process Child relationship');
    }
}
