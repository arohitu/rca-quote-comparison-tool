/**
 * @description Service class for processing and transforming query results
 * @author RCA Development Team
 * @date 2024
 */
public with sharing class RCA_DataProcessorService {
    
    /**
     * @description Process self relationship results
     * @param queryResult Query result containing records
     * @param configObj Configuration metadata
     * @param quote1Id First quote ID
     * @param quote2Id Second quote ID
     * @param fieldDefinitions Field definitions
     * @param payload Payload to populate
     */
    public static void processSelfResults(
        RCA_DataStructures.QueryResult queryResult,
        RCA_Comparison_Object__mdt configObj,
        Id quote1Id,
        Id quote2Id,
        List<RCA_DataStructures.FieldDefinition> fieldDefinitions,
        RCA_DataStructures.ComparisonPayload payload
    ) {
        // Create sections for both quotes
        RCA_DataStructures.ObjectSection quote1Section = new RCA_DataStructures.ObjectSection(configObj.Label);
        RCA_DataStructures.ObjectSection quote2Section = new RCA_DataStructures.ObjectSection(configObj.Label);
        quote1Section.fields = fieldDefinitions;
        quote2Section.fields = fieldDefinitions;
        
        // Assign records to appropriate sections
        for (SObject record : queryResult.records) {
            if (record.Id == quote1Id) {
                quote1Section.record = record;
            } else if (record.Id == quote2Id) {
                quote2Section.record = record;
            }
        }
        
        payload.quote1Data.put(configObj.Object_API_Name__c, quote1Section);
        payload.quote2Data.put(configObj.Object_API_Name__c, quote2Section);
    }
    
    /**
     * @description Process parent relationship results
     * @param queryResult Query result containing records
     * @param configObj Configuration metadata
     * @param quote1Id First quote ID
     * @param quote2Id Second quote ID
     * @param fieldDefinitions Field definitions
     * @param payload Payload to populate
     */
    public static void processParentResults(
        RCA_DataStructures.QueryResult queryResult,
        RCA_Comparison_Object__mdt configObj,
        Id quote1Id,
        Id quote2Id,
        List<RCA_DataStructures.FieldDefinition> fieldDefinitions,
        RCA_DataStructures.ComparisonPayload payload
    ) {
        // Get quote to parent mapping
        Map<Id, Id> quoteToParentMap = getQuoteToParentMapping(quote1Id, quote2Id, configObj.Relationship_Name__c);
        
        // Create sections
        RCA_DataStructures.ObjectSection quote1Section = new RCA_DataStructures.ObjectSection(configObj.Label);
        RCA_DataStructures.ObjectSection quote2Section = new RCA_DataStructures.ObjectSection(configObj.Label);
        quote1Section.fields = fieldDefinitions;
        quote2Section.fields = fieldDefinitions;
        
        // Assign parent records to appropriate sections
        for (SObject parentRecord : queryResult.records) {
            Id quote1ParentId = quoteToParentMap.get(quote1Id);
            Id quote2ParentId = quoteToParentMap.get(quote2Id);
            
            if (parentRecord.Id == quote1ParentId) {
                quote1Section.record = parentRecord;
            }
            if (parentRecord.Id == quote2ParentId) {
                quote2Section.record = parentRecord;
            }
        }
        
        payload.quote1Data.put(configObj.Object_API_Name__c, quote1Section);
        payload.quote2Data.put(configObj.Object_API_Name__c, quote2Section);
    }
    
    /**
     * @description Process child relationship results
     * @param queryResult Query result containing records
     * @param configObj Configuration metadata
     * @param quote1Id First quote ID
     * @param quote2Id Second quote ID
     * @param fieldDefinitions Field definitions
     * @param payload Payload to populate
     */
    public static void processChildResults(
        RCA_DataStructures.QueryResult queryResult,
        RCA_Comparison_Object__mdt configObj,
        Id quote1Id,
        Id quote2Id,
        List<RCA_DataStructures.FieldDefinition> fieldDefinitions,
        RCA_DataStructures.ComparisonPayload payload
    ) {
        // Create sections
        RCA_DataStructures.ObjectSection quote1Section = new RCA_DataStructures.ObjectSection(configObj.Label);
        RCA_DataStructures.ObjectSection quote2Section = new RCA_DataStructures.ObjectSection(configObj.Label);
        quote1Section.fields = fieldDefinitions;
        quote2Section.fields = fieldDefinitions;
        
        if (String.isBlank(configObj.Parent_Identifier_Field__c)) {
            // Direct child records
            processDirectChildRecords(queryResult.records, quote1Id, quote2Id, quote1Section, quote2Section);
        } else {
            // Grandchild records
            processGrandchildRecords(queryResult.records, configObj, quote1Id, quote2Id, quote1Section, quote2Section);
        }
        
        payload.quote1Data.put(configObj.Object_API_Name__c, quote1Section);
        payload.quote2Data.put(configObj.Object_API_Name__c, quote2Section);
    }
    
    /**
     * @description Process direct child records
     * @param childRecords List of child records
     * @param quote1Id First quote ID
     * @param quote2Id Second quote ID
     * @param quote1Section Section for quote 1
     * @param quote2Section Section for quote 2
     */
    private static void processDirectChildRecords(
        List<SObject> childRecords,
        Id quote1Id,
        Id quote2Id,
        RCA_DataStructures.ObjectSection quote1Section,
        RCA_DataStructures.ObjectSection quote2Section
    ) {
        for (SObject record : childRecords) {
            Id quoteId = (Id) record.get('QuoteId');
            RCA_DataStructures.ChildWrapper wrapper = new RCA_DataStructures.ChildWrapper();
            wrapper.record = record;
            
            if (quoteId == quote1Id) {
                quote1Section.childRecords.add(wrapper);
            } else if (quoteId == quote2Id) {
                quote2Section.childRecords.add(wrapper);
            }
        }
    }
    
    /**
     * @description Process grandchild records and group them under their parents
     * @param grandchildRecords List of grandchild records
     * @param configObj Configuration metadata
     * @param quote1Id First quote ID
     * @param quote2Id Second quote ID
     * @param quote1Section Section for quote 1
     * @param quote2Section Section for quote 2
     */
    private static void processGrandchildRecords(
        List<SObject> grandchildRecords,
        RCA_Comparison_Object__mdt configObj,
        Id quote1Id,
        Id quote2Id,
        RCA_DataStructures.ObjectSection quote1Section,
        RCA_DataStructures.ObjectSection quote2Section
    ) {
        // Get parent line items to group grandchildren
        List<QuoteLineItem> lineItems = RCA_QueryBuilderService.getParentLineItems(quote1Id, quote2Id);
        
        Map<Id, Id> lineItemToQuoteMap = new Map<Id, Id>();
        for (QuoteLineItem li : lineItems) {
            lineItemToQuoteMap.put(li.Id, li.QuoteId);
        }
        
        // Group grandchildren by their parent line item
        Map<Id, List<SObject>> parentToGrandchildrenMap = new Map<Id, List<SObject>>();
        for (SObject grandchild : grandchildRecords) {
            Id parentId = (Id) grandchild.get(configObj.Parent_Identifier_Field__c);
            if (!parentToGrandchildrenMap.containsKey(parentId)) {
                parentToGrandchildrenMap.put(parentId, new List<SObject>());
            }
            parentToGrandchildrenMap.get(parentId).add(grandchild);
        }
        
        // Create child wrappers for each parent line item
        for (QuoteLineItem lineItem : lineItems) {
            RCA_DataStructures.ChildWrapper wrapper = new RCA_DataStructures.ChildWrapper();
            wrapper.record = lineItem;
            wrapper.grandchildRecords = parentToGrandchildrenMap.get(lineItem.Id);
            
            if (wrapper.grandchildRecords == null) {
                wrapper.grandchildRecords = new List<SObject>();
            }
            
            if (lineItem.QuoteId == quote1Id) {
                quote1Section.childRecords.add(wrapper);
            } else if (lineItem.QuoteId == quote2Id) {
                quote2Section.childRecords.add(wrapper);
            }
        }
    }
    
    /**
     * @description Get mapping from quote ID to parent ID
     * @param quote1Id First quote ID
     * @param quote2Id Second quote ID
     * @param relationshipName Name of the relationship field
     * @return Map from quote ID to parent ID
     */
    private static Map<Id, Id> getQuoteToParentMapping(Id quote1Id, Id quote2Id, String relationshipName) {
        String parentQuery = 'SELECT ' + relationshipName + ' FROM Quote WHERE Id IN (:quote1Id, :quote2Id)';
        
        // Use FOR loop for consistency (though only 2 records expected)
        List<Quote> quotes = new List<Quote>();
        for (Quote q : (List<Quote>) Database.query(parentQuery)) {
            quotes.add(q);
        }
        
        Map<Id, Id> quoteToParentMap = new Map<Id, Id>();
        for (Quote q : quotes) {
            Id parentId = (Id) q.get(relationshipName);
            if (parentId != null) {
                quoteToParentMap.put(q.Id, parentId);
            }
        }
        
        return quoteToParentMap;
    }
    
    /**
     * @description Enhance field definitions with relationship field mapping
     * @param fieldDefinitions List of field definitions to enhance
     * @param objectApiName Object API name for context
     * @return Enhanced field definitions
     */
    public static List<RCA_DataStructures.FieldDefinition> enhanceFieldDefinitions(
        List<RCA_DataStructures.FieldDefinition> fieldDefinitions,
        String objectApiName
    ) {
        List<RCA_DataStructures.FieldDefinition> enhanced = new List<RCA_DataStructures.FieldDefinition>();
        
        for (RCA_DataStructures.FieldDefinition field : fieldDefinitions) {
            RCA_DataStructures.FieldDefinition enhancedField = new RCA_DataStructures.FieldDefinition();
            enhancedField.apiName = field.apiName;
            enhancedField.type = field.type;
            
            // Special handling for Product field on QuoteLineItem
            if (objectApiName == 'QuoteLineItem' && field.apiName == 'Product2Id') {
                enhancedField.label = 'Product';
            } else {
                enhancedField.label = field.label;
            }
            
            enhanced.add(enhancedField);
        }
        
        return enhanced;
    }
    
    /**
     * @description Process query result based on relationship type
     * @param queryResult Query result to process
     * @param configObj Configuration metadata
     * @param quote1Id First quote ID
     * @param quote2Id Second quote ID
     * @param fieldDefinitions Field definitions
     * @param payload Payload to populate
     */
    public static void processQueryResult(
        RCA_DataStructures.QueryResult queryResult,
        RCA_Comparison_Object__mdt configObj,
        Id quote1Id,
        Id quote2Id,
        List<RCA_DataStructures.FieldDefinition> fieldDefinitions,
        RCA_DataStructures.ComparisonPayload payload
    ) {
        switch on queryResult.relationshipType {
            when 'Self' {
                processSelfResults(queryResult, configObj, quote1Id, quote2Id, fieldDefinitions, payload);
            }
            when 'Parent' {
                processParentResults(queryResult, configObj, quote1Id, quote2Id, fieldDefinitions, payload);
            }
            when 'Child' {
                processChildResults(queryResult, configObj, quote1Id, quote2Id, fieldDefinitions, payload);
            }
        }
    }
}
