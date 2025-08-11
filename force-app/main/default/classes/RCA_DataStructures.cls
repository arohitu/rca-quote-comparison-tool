/**
 * @description Centralized data structures for RCA Quote Comparison Tool
 * @author RCA Development Team
 * @date 2024
 */
public with sharing class RCA_DataStructures {
    
    /**
     * @description Main container for the entire response payload
     */
    public class ComparisonPayload {
        @AuraEnabled public Map<String, ObjectSection> quote1Data;
        @AuraEnabled public Map<String, ObjectSection> quote2Data;
        @AuraEnabled public List<String> sectionOrder;

        public ComparisonPayload() {
            this.quote1Data = new Map<String, ObjectSection>();
            this.quote2Data = new Map<String, ObjectSection>();
            this.sectionOrder = new List<String>();
        }
    }

    /**
     * @description Represents a section for a single object (e.g., Opportunity details)
     */
    public class ObjectSection {
        @AuraEnabled public String objectLabel;
        @AuraEnabled public SObject record; // For Parent/Self
        @AuraEnabled public List<ChildWrapper> childRecords; // For Child
        @AuraEnabled public List<FieldDefinition> fields;

        public ObjectSection(String label) {
            this.objectLabel = label;
            this.childRecords = new List<ChildWrapper>();
            this.fields = new List<FieldDefinition>();
        }
    }

    /**
     * @description Wrapper for a child record that can contain its own children (grandchildren)
     */
    public class ChildWrapper {
        @AuraEnabled public SObject record;
        @AuraEnabled public List<SObject> grandchildRecords;
        
        public ChildWrapper() {
            this.grandchildRecords = new List<SObject>();
        }
    }

    /**
     * @description Describes a field from the field set
     */
    public class FieldDefinition {
        @AuraEnabled public String apiName;
        @AuraEnabled public String label;
        @AuraEnabled public String type;
    }
    
    /**
     * @description Query parameters for dynamic SOQL building
     */
    public class QueryParameters {
        public String objectApiName;
        public List<FieldDefinition> fields;
        public String whereClause;
        public RCA_Comparison_Object__mdt configObject;
        
        public QueryParameters(String objectApiName, List<FieldDefinition> fields, String whereClause) {
            this.objectApiName = objectApiName;
            this.fields = fields;
            this.whereClause = whereClause;
        }
    }
    
    /**
     * @description Result container for query execution
     */
    public class QueryResult {
        public List<SObject> records;
        public String objectApiName;
        public String relationshipType;
        
        public QueryResult(List<SObject> records, String objectApiName, String relationshipType) {
            this.records = records;
            this.objectApiName = objectApiName;
            this.relationshipType = relationshipType;
        }
    }
}
