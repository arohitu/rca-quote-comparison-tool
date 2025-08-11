import { LightningElement, api } from 'lwc';

export default class RcaComparisonSection extends LightningElement {
    @api section; // Section data containing quote1Section, quote2Section, etc.
    @api quote1Name;
    @api quote2Name;

    /**
     * Check if section has parent/self records
     */
    get hasParentRecord() {
        return this.section && this.section.hasParentRecord;
    }

    /**
     * Check if section has child records
     */
    get hasChildRecords() {
        return this.section && this.section.hasChildRecords;
    }

    /**
     * Get quote 1 section data
     */
    get quote1Section() {
        return this.section ? this.section.quote1Section : null;
    }

    /**
     * Get quote 2 section data
     */
    get quote2Section() {
        return this.section ? this.section.quote2Section : null;
    }

    /**
     * Get object label for the section
     */
    get objectLabel() {
        return this.section ? this.section.objectLabel : '';
    }

    /**
     * Get fields with values for quote 1 parent/self record
     */
    get quote1FieldsWithValues() {
        return this.quote1Section && this.quote1Section.fieldsWithValues 
            ? this.quote1Section.fieldsWithValues 
            : [];
    }

    /**
     * Get fields with values for quote 2 parent/self record
     */
    get quote2FieldsWithValues() {
        return this.quote2Section && this.quote2Section.fieldsWithValues 
            ? this.quote2Section.fieldsWithValues 
            : [];
    }

    /**
     * Get child records with values for quote 1
     */
    get quote1ChildRecordsWithValues() {
        return this.quote1Section && this.quote1Section.childRecordsWithValues 
            ? this.quote1Section.childRecordsWithValues 
            : [];
    }

    /**
     * Get child records with values for quote 2
     */
    get quote2ChildRecordsWithValues() {
        return this.quote2Section && this.quote2Section.childRecordsWithValues 
            ? this.quote2Section.childRecordsWithValues 
            : [];
    }
}
