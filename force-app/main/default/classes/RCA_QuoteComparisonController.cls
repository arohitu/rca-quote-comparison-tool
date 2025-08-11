/**
 * @description Main controller for RCA Quote Comparison Tool
 * Orchestrates calls to service classes without containing business logic
 * @author RCA Development Team
 * @date 2024
 */
public with sharing class RCA_QuoteComparisonController {
    
    /**
     * @description Main method to get comparison details for two quotes
     * @param quote1Id First quote ID
     * @param quote2Id Second quote ID
     * @return ComparisonPayload containing all comparison data
     */
    @AuraEnabled
    public static RCA_DataStructures.ComparisonPayload getComparisonDetails(Id quote1Id, Id quote2Id) {
        try {
            // Validate inputs
            if (quote1Id == null || quote2Id == null) {
                throw new AuraHandledException('Both quote IDs are required.');
            }
            
            if (quote1Id == quote2Id) {
                throw new AuraHandledException('Please select different quotes for comparison.');
            }
            
            // Get configuration
            List<RCA_Comparison_Object__mdt> comparisonObjects = RCA_ConfigurationService.getComparisonObjects();
            
            if (comparisonObjects.isEmpty()) {
                throw new AuraHandledException('No comparison objects configured. Please configure RCA_Comparison_Object__mdt records.');
            }
            
            // Validate configuration
            if (!RCA_ConfigurationService.validateConfiguration(comparisonObjects)) {
                throw new AuraHandledException('Invalid configuration detected. Please check field sets for all configured objects.');
            }
            
            // Initialize payload
            RCA_DataStructures.ComparisonPayload payload = new RCA_DataStructures.ComparisonPayload();
            
            // Process each configured object
            for (RCA_Comparison_Object__mdt configObj : comparisonObjects) {
                processObjectComparison(configObj, quote1Id, quote2Id, payload);
                payload.sectionOrder.add(configObj.Object_API_Name__c);
            }
            
            return payload;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving comparison data: ' + e.getMessage());
        }
    }
    
    /**
     * @description Process comparison for a single object type
     * @param configObj Configuration metadata
     * @param quote1Id First quote ID
     * @param quote2Id Second quote ID
     * @param payload Payload to populate
     */
    private static void processObjectComparison(
        RCA_Comparison_Object__mdt configObj, 
        Id quote1Id, 
        Id quote2Id, 
        RCA_DataStructures.ComparisonPayload payload
    ) {
        // Get field configuration
        Schema.FieldSet fieldSet = RCA_ConfigurationService.getFieldSet(configObj.Object_API_Name__c);
        if (fieldSet == null) {
            System.debug('No field set found for object: ' + configObj.Object_API_Name__c);
            return;
        }
        
        List<RCA_DataStructures.FieldDefinition> fieldDefinitions = RCA_ConfigurationService.buildFieldDefinitions(fieldSet);
        
        // Enhance field definitions with relationship field mapping
        fieldDefinitions = RCA_DataProcessorService.enhanceFieldDefinitions(fieldDefinitions, configObj.Object_API_Name__c);
        
        // Execute query
        RCA_DataStructures.QueryResult queryResult = RCA_QueryBuilderService.executeQuery(
            configObj, 
            quote1Id, 
            quote2Id, 
            fieldDefinitions
        );
        
        // Process results
        RCA_DataProcessorService.processQueryResult(
            queryResult, 
            configObj, 
            quote1Id, 
            quote2Id, 
            fieldDefinitions, 
            payload
        );
    }
}
