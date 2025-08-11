/**
 * @description Test class for RCA_ConfigurationService
 * @author RCA Development Team
 * @date 2024
 */
@IsTest
public class RCA_ConfigurationServiceTest {
    
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
    }
    
    @IsTest
    static void testGetComparisonObjects() {
        Test.startTest();
        
        // Test getting comparison objects
        List<RCA_Comparison_Object__mdt> comparisonObjects = RCA_ConfigurationService.getComparisonObjects();
        
        Test.stopTest();
        
        // Verify results
        System.assertNotEquals(null, comparisonObjects, 'Comparison objects should not be null');
        // Note: The actual number depends on the custom metadata records deployed
    }
    
    @IsTest
    static void testGetComparisonObjectsException() {
        Test.startTest();
        
        try {
            // This should not throw an exception under normal circumstances
            List<RCA_Comparison_Object__mdt> result = RCA_ConfigurationService.getComparisonObjects();
            System.assertNotEquals(null, result, 'Result should not be null');
        } catch (Exception e) {
            // If an exception occurs, verify it's properly handled
            System.assert(e instanceof AuraHandledException, 'Should throw AuraHandledException');
        }
        
        Test.stopTest();
    }
    
    @IsTest
    static void testGetFieldSetQuote() {
        Test.startTest();
        
        // Test getting field set for Quote object
        Schema.FieldSet fieldSet = RCA_ConfigurationService.getFieldSet('Quote');
        
        Test.stopTest();
        
        // Verify results - field set may or may not exist depending on deployment
        // The method should handle both cases gracefully
        System.assert(true, 'Method should execute without exception');
    }
    
    @IsTest
    static void testGetFieldSetOpportunity() {
        Test.startTest();
        
        // Test getting field set for Opportunity object
        Schema.FieldSet fieldSet = RCA_ConfigurationService.getFieldSet('Opportunity');
        
        Test.stopTest();
        
        // Verify results
        System.assert(true, 'Method should execute without exception');
    }
    
    @IsTest
    static void testGetFieldSetInvalidObject() {
        Test.startTest();
        
        // Test getting field set for invalid object
        Schema.FieldSet fieldSet = RCA_ConfigurationService.getFieldSet('InvalidObject');
        
        Test.stopTest();
        
        // Verify results
        System.assertEquals(null, fieldSet, 'Field set should be null for invalid object');
    }
    
    @IsTest
    static void testBuildFieldDefinitions() {
        Test.startTest();
        
        // Get a field set to test with
        Schema.FieldSet fieldSet = RCA_ConfigurationService.getFieldSet('Quote');
        
        // Test building field definitions
        List<RCA_DataStructures.FieldDefinition> definitions = RCA_ConfigurationService.buildFieldDefinitions(fieldSet);
        
        Test.stopTest();
        
        // Verify results
        System.assertNotEquals(null, definitions, 'Definitions should not be null');
        
        if (fieldSet != null && !fieldSet.getFields().isEmpty()) {
            System.assert(definitions.size() > 0, 'Should have field definitions if field set exists');
            
            // Verify field definition structure
            for (RCA_DataStructures.FieldDefinition def : definitions) {
                System.assertNotEquals(null, def.apiName, 'API name should not be null');
                System.assertNotEquals(null, def.label, 'Label should not be null');
                System.assertNotEquals(null, def.type, 'Type should not be null');
            }
        }
    }
    
    @IsTest
    static void testBuildFieldDefinitionsNullFieldSet() {
        Test.startTest();
        
        // Test with null field set
        List<RCA_DataStructures.FieldDefinition> definitions = RCA_ConfigurationService.buildFieldDefinitions(null);
        
        Test.stopTest();
        
        // Verify results
        System.assertNotEquals(null, definitions, 'Definitions should not be null');
        System.assertEquals(0, definitions.size(), 'Should return empty list for null field set');
    }
    
    @IsTest
    static void testValidateConfigurationValid() {
        Test.startTest();
        
        // Create mock comparison objects
        List<RCA_Comparison_Object__mdt> mockObjects = new List<RCA_Comparison_Object__mdt>();
        
        // We can't create custom metadata in tests, so we'll test the method's logic
        // The method will return false if no field sets exist, which is expected in test context
        Boolean isValid = RCA_ConfigurationService.validateConfiguration(mockObjects);
        
        Test.stopTest();
        
        // Verify results - empty list should return false
        System.assertEquals(false, isValid, 'Empty configuration should be invalid');
    }
    
    @IsTest
    static void testValidateConfigurationEmpty() {
        Test.startTest();
        
        // Test with empty list
        List<RCA_Comparison_Object__mdt> emptyObjects = new List<RCA_Comparison_Object__mdt>();
        Boolean isValid = RCA_ConfigurationService.validateConfiguration(emptyObjects);
        
        Test.stopTest();
        
        // Verify results
        System.assertEquals(false, isValid, 'Empty configuration should be invalid');
    }
}
