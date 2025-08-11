/**
 * @description Service class for handling RCA Comparison configuration
 * @author RCA Development Team
 * @date 2024
 */
public with sharing class RCA_ConfigurationService {
    
    /**
     * @description Get all comparison object configurations
     * @return List of comparison object metadata records
     */
    public static List<RCA_Comparison_Object__mdt> getComparisonObjects() {
        try {
            return [
                SELECT Label, Object_API_Name__c, Relationship_Type__c, 
                       Relationship_Name__c, Parent_Identifier_Field__c, Display_Order__c
                FROM RCA_Comparison_Object__mdt
                ORDER BY Display_Order__c ASC
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving comparison configuration: ' + e.getMessage());
        }
    }
    
    /**
     * @description Get field set for a specific object
     * @param objectApiName The API name of the object
     * @return Schema.FieldSet The field set for the object
     */
    public static Schema.FieldSet getFieldSet(String objectApiName) {
        try {
            Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(objectApiName);
            if (sObjectType == null) {
                return null;
            }
            
            Schema.DescribeSObjectResult describe = sObjectType.getDescribe();
            Map<String, Schema.FieldSet> fieldSets = describe.fieldSets.getMap();
            return fieldSets.get('RCA_Comparison');
        } catch (Exception e) {
            System.debug('Error getting field set for ' + objectApiName + ': ' + e.getMessage());
            return null;
        }
    }
    
    /**
     * @description Build field definitions from field set
     * @param fieldSet The field set to process
     * @return List of field definitions
     */
    public static List<RCA_DataStructures.FieldDefinition> buildFieldDefinitions(Schema.FieldSet fieldSet) {
        List<RCA_DataStructures.FieldDefinition> definitions = new List<RCA_DataStructures.FieldDefinition>();
        
        if (fieldSet == null) {
            return definitions;
        }
        
        for (Schema.FieldSetMember field : fieldSet.getFields()) {
            RCA_DataStructures.FieldDefinition def = new RCA_DataStructures.FieldDefinition();
            def.apiName = field.getFieldPath();
            def.label = field.getLabel();
            def.type = String.valueOf(field.getType());
            definitions.add(def);
        }
        
        return definitions;
    }
    
    /**
     * @description Build field definitions for objects without field sets (using specific fields)
     * @param objectApiName The object API name
     * @return List of field definitions
     */
    public static List<RCA_DataStructures.FieldDefinition> buildFieldDefinitionsFromDescribe(String objectApiName) {
        List<RCA_DataStructures.FieldDefinition> definitions = new List<RCA_DataStructures.FieldDefinition>();
        
        try {
            Schema.SObjectType objectType = Schema.getGlobalDescribe().get(objectApiName);
            if (objectType == null) {
                return definitions;
            }
            
            Map<String, Schema.SObjectField> fieldMap = objectType.getDescribe().fields.getMap();
            
            // Define specific fields for each object type
            Set<String> fieldsToInclude = new Set<String>();
            if (objectApiName == 'QuoteLineItemAttribute') {
                fieldsToInclude.addAll(new Set<String>{'AttributeName', 'AttributeValue'});
            }
            
            for (String fieldName : fieldsToInclude) {
                if (fieldMap.containsKey(fieldName.toLowerCase())) {
                    Schema.DescribeFieldResult fieldDescribe = fieldMap.get(fieldName.toLowerCase()).getDescribe();
                    
                    // Only include accessible fields
                    if (fieldDescribe.isAccessible()) {
                        RCA_DataStructures.FieldDefinition def = new RCA_DataStructures.FieldDefinition();
                        def.apiName = fieldDescribe.getName();
                        def.label = fieldDescribe.getLabel();
                        def.type = String.valueOf(fieldDescribe.getType());
                        definitions.add(def);
                    }
                }
            }
            
            // Sort by label for consistent display
            definitions.sort();
            
        } catch (Exception e) {
            System.debug('Error building field definitions for ' + objectApiName + ': ' + e.getMessage());
        }
        
        return definitions;
    }
    
    /**
     * @description Validate configuration for completeness
     * @param comparisonObjects List of configuration objects to validate
     * @return Boolean indicating if configuration is valid
     */
    public static Boolean validateConfiguration(List<RCA_Comparison_Object__mdt> comparisonObjects) {
        if (comparisonObjects.isEmpty()) {
            return false;
        }
        
        // Check if each configured object has valid field configuration
        for (RCA_Comparison_Object__mdt configObj : comparisonObjects) {
            // Objects that use field describe approach (like QuoteLineItemAttribute)
            if (configObj.Object_API_Name__c == 'QuoteLineItemAttribute') {
                List<RCA_DataStructures.FieldDefinition> fieldDefinitions = buildFieldDefinitionsFromDescribe(configObj.Object_API_Name__c);
                if (fieldDefinitions.isEmpty()) {
                    System.debug('No valid field definitions found for: ' + configObj.Object_API_Name__c);
                    return false;
                }
            } else {
                // Objects that use field sets
                Schema.FieldSet fieldSet = getFieldSet(configObj.Object_API_Name__c);
                if (fieldSet == null || fieldSet.getFields().isEmpty()) {
                    System.debug('No valid field set found for: ' + configObj.Object_API_Name__c);
                    return false;
                }
            }
        }
        
        return true;
    }
}
