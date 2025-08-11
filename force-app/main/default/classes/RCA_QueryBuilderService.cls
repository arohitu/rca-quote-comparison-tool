/**
 * @description Service class for building and executing dynamic SOQL queries
 * @author RCA Development Team
 * @date 2024
 */
public with sharing class RCA_QueryBuilderService {
    
    /**
     * @description Build dynamic SOQL query string
     * @param objectApiName The object to query
     * @param fields List of fields to include
     * @param whereClause WHERE clause for the query
     * @return String The complete SOQL query
     */
    public static String buildSOQLQuery(String objectApiName, List<RCA_DataStructures.FieldDefinition> fields, String whereClause) {
        Set<String> fieldNames = new Set<String>();
        fieldNames.add('Id'); // Always include Id
        
        // Add relationship fields based on object type for data processing
        if (objectApiName == 'QuoteLineItem') {
            fieldNames.add('QuoteId'); // Required for grouping by quote
        } else if (objectApiName == 'Quote') {
            fieldNames.add('OpportunityId'); // Required for parent relationships
        }
        
        for (RCA_DataStructures.FieldDefinition field : fields) {
            fieldNames.add(field.apiName);
        }
        
        String soql = 'SELECT ' + String.join(new List<String>(fieldNames), ', ') + 
                     ' FROM ' + objectApiName;
        
        if (String.isNotBlank(whereClause)) {
            soql += ' WHERE ' + whereClause;
        }
        
        return soql;
    }
    
    /**
     * @description Build SOQL query with relationship fields based on configuration
     * @param configObj Configuration metadata object
     * @param fields List of fields to include
     * @param whereClause WHERE clause for the query
     * @return String The complete SOQL query with necessary relationship fields
     */
    public static String buildSOQLQueryWithRelationshipFields(
        RCA_Comparison_Object__mdt configObj, 
        List<RCA_DataStructures.FieldDefinition> fields, 
        String whereClause
    ) {
        Set<String> fieldNames = new Set<String>();
        fieldNames.add('Id'); // Always include Id
        
        // Add relationship fields based on object type for data processing
        if (configObj.Object_API_Name__c == 'QuoteLineItem') {
            fieldNames.add('QuoteId'); // Required for grouping by quote
            fieldNames.add('Product2.Name'); // Product name for better display
        } else if (configObj.Object_API_Name__c == 'Quote') {
            fieldNames.add('OpportunityId'); // Required for parent relationships
        } else if (configObj.Object_API_Name__c == 'QuoteLineItemAttribute') {
            fieldNames.add('QuoteLineItemId'); // Required for grouping by line item
        }
        
        // Add parent identifier field if this is a grandchild relationship
        if (String.isNotBlank(configObj.Parent_Identifier_Field__c)) {
            fieldNames.add(configObj.Parent_Identifier_Field__c);
        }
        
        // Add configured fields
        for (RCA_DataStructures.FieldDefinition field : fields) {
            fieldNames.add(field.apiName);
        }
        
        String soql = 'SELECT ' + String.join(new List<String>(fieldNames), ', ') + 
                     ' FROM ' + configObj.Object_API_Name__c;
        
        if (String.isNotBlank(whereClause)) {
            soql += ' WHERE ' + whereClause;
        }
        
        // Add ordering for better side-by-side comparison
        soql += getOrderByClause(configObj.Object_API_Name__c);
        
        return soql;
    }
    
    /**
     * @description Get ORDER BY clause for consistent record ordering
     * @param objectApiName The object API name
     * @return String ORDER BY clause
     */
    private static String getOrderByClause(String objectApiName) {
        if (objectApiName == 'QuoteLineItem') {
            return ' ORDER BY Product2.Name, SortOrder, CreatedDate';
        } else if (objectApiName == 'QuoteLineItemAttribute') {
            return ' ORDER BY AttributeName, CreatedDate';
        } else if (objectApiName == 'Quote') {
            return ' ORDER BY Name, CreatedDate';
        } else if (objectApiName == 'Opportunity') {
            return ' ORDER BY Name, CreatedDate';
        }
        return ' ORDER BY CreatedDate';
    }
    
    /**
     * @description Execute query for self relationship (Quote object itself)
     * @param configObj Configuration metadata
     * @param quote1Id First quote ID
     * @param quote2Id Second quote ID
     * @param fieldDefinitions Field definitions for the object
     * @return QueryResult containing the results
     */
    public static RCA_DataStructures.QueryResult executeSelfQuery(
        RCA_Comparison_Object__mdt configObj,
        Id quote1Id, 
        Id quote2Id,
        List<RCA_DataStructures.FieldDefinition> fieldDefinitions
    ) {
        String whereClause = 'Id IN (:quote1Id, :quote2Id)';
        String soqlQuery = buildSOQLQuery(configObj.Object_API_Name__c, fieldDefinitions, whereClause);
        
        // Use FOR loop to handle large result sets
        List<SObject> records = new List<SObject>();
        for (SObject record : Database.query(soqlQuery)) {
            records.add(record);
        }
        
        return new RCA_DataStructures.QueryResult(records, configObj.Object_API_Name__c, 'Self');
    }
    
    /**
     * @description Execute query for parent relationship
     * @param configObj Configuration metadata
     * @param quote1Id First quote ID
     * @param quote2Id Second quote ID
     * @param fieldDefinitions Field definitions for the object
     * @return QueryResult containing the results
     */
    public static RCA_DataStructures.QueryResult executeParentQuery(
        RCA_Comparison_Object__mdt configObj,
        Id quote1Id, 
        Id quote2Id,
        List<RCA_DataStructures.FieldDefinition> fieldDefinitions
    ) {
        // First get the parent IDs from quotes
        String parentQuery = 'SELECT ' + configObj.Relationship_Name__c + ' FROM Quote WHERE Id IN (:quote1Id, :quote2Id)';
        List<Quote> quotes = Database.query(parentQuery);
        
        Set<Id> parentIds = new Set<Id>();
        for (Quote q : quotes) {
            Id parentId = (Id) q.get(configObj.Relationship_Name__c);
            if (parentId != null) {
                parentIds.add(parentId);
            }
        }
        
        List<SObject> records = new List<SObject>();
        if (!parentIds.isEmpty()) {
            String whereClause = 'Id IN :parentIds';
            String soqlQuery = buildSOQLQuery(configObj.Object_API_Name__c, fieldDefinitions, whereClause);
            
            // Use FOR loop to handle large result sets
            for (SObject record : Database.query(soqlQuery)) {
                records.add(record);
            }
        }
        
        return new RCA_DataStructures.QueryResult(records, configObj.Object_API_Name__c, 'Parent');
    }
    
    /**
     * @description Execute query for child relationship
     * @param configObj Configuration metadata
     * @param quote1Id First quote ID
     * @param quote2Id Second quote ID
     * @param fieldDefinitions Field definitions for the object
     * @return QueryResult containing the results
     */
    public static RCA_DataStructures.QueryResult executeChildQuery(
        RCA_Comparison_Object__mdt configObj,
        Id quote1Id, 
        Id quote2Id,
        List<RCA_DataStructures.FieldDefinition> fieldDefinitions
    ) {
        String whereClause = 'QuoteId IN (:quote1Id, :quote2Id)';
        if (String.isNotBlank(configObj.Parent_Identifier_Field__c)) {
            // This is a grandchild relationship - optimize by getting parent IDs first
            List<Id> parentIds = new List<Id>();
            for (QuoteLineItem qli : [SELECT Id FROM QuoteLineItem WHERE QuoteId IN (:quote1Id, :quote2Id) LIMIT 10000]) {
                parentIds.add(qli.Id);
            }
            
            // If no parent records found, return empty result to avoid unnecessary query
            if (parentIds.isEmpty()) {
                return new RCA_DataStructures.QueryResult(new List<SObject>(), configObj.Object_API_Name__c, 'Child');
            }
            
            whereClause = configObj.Parent_Identifier_Field__c + ' IN :parentIds';
        }
        
        String soqlQuery = buildSOQLQueryWithRelationshipFields(configObj, fieldDefinitions, whereClause);
        
        // Use FOR loop to handle large result sets and avoid "too many rows" error
        List<SObject> records = new List<SObject>();
        for (SObject record : Database.query(soqlQuery)) {
            records.add(record);
        }
        
        return new RCA_DataStructures.QueryResult(records, configObj.Object_API_Name__c, 'Child');
    }
    
    /**
     * @description Get parent line items for grandchild processing
     * @param quote1Id First quote ID
     * @param quote2Id Second quote ID
     * @return List of QuoteLineItem records
     */
    public static List<QuoteLineItem> getParentLineItems(Id quote1Id, Id quote2Id) {
        return [
            SELECT Id, QuoteId 
            FROM QuoteLineItem 
            WHERE QuoteId IN (:quote1Id, :quote2Id)
        ];
    }
    
    /**
     * @description Execute query based on relationship type
     * @param configObj Configuration metadata
     * @param quote1Id First quote ID
     * @param quote2Id Second quote ID
     * @param fieldDefinitions Field definitions for the object
     * @return QueryResult containing the results
     */
    public static RCA_DataStructures.QueryResult executeQuery(
        RCA_Comparison_Object__mdt configObj,
        Id quote1Id, 
        Id quote2Id,
        List<RCA_DataStructures.FieldDefinition> fieldDefinitions
    ) {
        switch on configObj.Relationship_Type__c {
            when 'Self' {
                return executeSelfQuery(configObj, quote1Id, quote2Id, fieldDefinitions);
            }
            when 'Parent' {
                return executeParentQuery(configObj, quote1Id, quote2Id, fieldDefinitions);
            }
            when 'Child' {
                return executeChildQuery(configObj, quote1Id, quote2Id, fieldDefinitions);
            }
            when else {
                throw new AuraHandledException('Unsupported relationship type: ' + configObj.Relationship_Type__c);
            }
        }
    }
}
