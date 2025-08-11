import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord } from 'lightning/uiRecordApi';
import getComparisonDetails from '@salesforce/apex/RCA_QuoteComparisonController.getComparisonDetails';

const QUOTE_FIELDS = ['Quote.Name', 'Quote.QuoteNumber'];

export default class RcaQuoteComparator extends LightningElement {
    @api recordId; // Current Quote ID from Quick Action
    @track comparisonQuoteId;
    @track comparisonData;
    @track isLoading = false;
    @track showComparison = false;
    @track error;

    // Current quote information
    @wire(getRecord, { recordId: '$recordId', fields: QUOTE_FIELDS })
    currentQuote;

    /**
     * Get the current quote name for display
     */
    get currentQuoteName() {
        return this.currentQuote.data ? this.currentQuote.data.fields.Name.value : 'Current Quote';
    }

    /**
     * Get the current quote number for display
     */
    get currentQuoteNumber() {
        return this.currentQuote.data ? this.currentQuote.data.fields.QuoteNumber.value : '';
    }

    /**
     * Get comparison quote name for display
     */
    get comparisonQuoteName() {
        return 'Comparison Quote';
    }

    /**
     * Transform comparison data into sections array for template iteration
     */
    get comparisonSections() {
        if (!this.comparisonData || !this.comparisonData.sectionOrder) {
            return [];
        }

        return this.comparisonData.sectionOrder.map(objectApiName => {
            const quote1Section = this.comparisonData.quote1Data[objectApiName];
            const quote2Section = this.comparisonData.quote2Data[objectApiName];
            
            // Transform sections to include field values
            const transformedQuote1Section = this.transformSectionWithFieldValues(quote1Section);
            const transformedQuote2Section = this.transformSectionWithFieldValues(quote2Section);
            
            return {
                objectApiName: objectApiName,
                objectLabel: quote1Section ? quote1Section.objectLabel : 'Unknown Object',
                quote1Section: transformedQuote1Section,
                quote2Section: transformedQuote2Section,
                hasChildRecords: quote1Section && quote1Section.childRecords && quote1Section.childRecords.length > 0,
                hasParentRecord: quote1Section && quote1Section.record
            };
        });
    }

    /**
     * Transform section to include computed field values
     */
    transformSectionWithFieldValues(section) {
        if (!section) return null;

        const transformedSection = { ...section };

        // Transform fields with values for parent/self records
        if (section.record && section.fields) {
            transformedSection.fieldsWithValues = section.fields.map(field => ({
                ...field,
                value: this.getFieldValue(section.record, field.apiName),
                formattedValue: this.formatFieldValue(this.getFieldValue(section.record, field.apiName), field.type)
            }));
        }

        // Transform child records with field values
        if (section.childRecords) {
            transformedSection.childRecordsWithValues = section.childRecords.map(childWrapper => ({
                ...childWrapper,
                fieldsWithValues: section.fields ? section.fields.map(field => ({
                    ...field,
                    value: this.getFieldValue(childWrapper.record, field.apiName),
                    formattedValue: this.formatFieldValue(this.getFieldValue(childWrapper.record, field.apiName), field.type)
                })) : []
            }));
        }

        return transformedSection;
    }

    /**
     * Handle quote selection from child component
     */
    handleQuoteSelection(event) {
        this.comparisonQuoteId = event.detail.selectedQuoteId;
    }

    /**
     * Handle compare event from child component
     */
    async handleCompare() {
        if (!this.comparisonQuoteId) {
            this.showToast('Error', 'Please select a comparison quote.', 'error');
            return;
        }

        if (this.comparisonQuoteId === this.recordId) {
            this.showToast('Error', 'Please select a different quote for comparison.', 'error');
            return;
        }

        this.isLoading = true;
        this.error = null;

        try {
            this.comparisonData = await getComparisonDetails({
                quote1Id: this.recordId,
                quote2Id: this.comparisonQuoteId
            });
            
            this.showComparison = true;
            
        } catch (error) {
            console.error('Error getting comparison data:', error);
            this.error = error.body ? error.body.message : error.message;
            this.showToast('Error', this.error, 'error');
        } finally {
            this.isLoading = false;
        }
    }

    /**
     * Handle back event from child component
     */
    handleBack() {
        this.showComparison = false;
        this.comparisonData = null;
        this.error = null;
    }

    /**
     * Get field value from record
     */
    getFieldValue(record, fieldApiName) {
        if (!record || !fieldApiName) {
            return '';
        }
        
        // Handle relationship fields (e.g., Account.Name)
        if (fieldApiName.includes('.')) {
            const parts = fieldApiName.split('.');
            let value = record;
            for (const part of parts) {
                value = value ? value[part] : null;
            }
            return value || '';
        }
        
        return record[fieldApiName] || '';
    }

    /**
     * Format field value for display
     */
    formatFieldValue(value, fieldType) {
        if (value === null || value === undefined || value === '') {
            return '--';
        }

        switch (fieldType?.toLowerCase()) {
            case 'currency':
                return new Intl.NumberFormat('en-US', {
                    style: 'currency',
                    currency: 'USD'
                }).format(value);
            case 'percent':
                return `${value}%`;
            case 'date':
                return new Date(value).toLocaleDateString();
            case 'datetime':
                return new Date(value).toLocaleString();
            case 'boolean':
                return value ? 'Yes' : 'No';
            default:
                return value;
        }
    }

    /**
     * Show toast message
     */
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }

    /**
     * Handle close modal
     */
    handleClose() {
        // Close the modal/quick action
        const closeEvent = new CustomEvent('close');
        this.dispatchEvent(closeEvent);
    }
}
