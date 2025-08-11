import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';

const QUOTE_FIELDS = ['Quote.Name', 'Quote.QuoteNumber'];

export default class RcaQuoteSelection extends LightningElement {
    @api recordId; // Current Quote ID
    @api selectedQuoteId; // Selected comparison quote ID
    @api isLoading = false;

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
     * Handle comparison quote selection
     */
    handleComparisonQuoteChange(event) {
        const selectedQuoteId = event.detail.recordId;
        
        // Dispatch custom event to parent
        const selectionEvent = new CustomEvent('quoteselection', {
            detail: {
                selectedQuoteId: selectedQuoteId
            }
        });
        this.dispatchEvent(selectionEvent);
    }

    /**
     * Handle compare button click
     */
    handleCompare() {
        // Dispatch compare event to parent
        const compareEvent = new CustomEvent('compare');
        this.dispatchEvent(compareEvent);
    }

    /**
     * Handle cancel button click
     */
    handleCancel() {
        // Dispatch cancel event to parent
        const cancelEvent = new CustomEvent('cancel');
        this.dispatchEvent(cancelEvent);
    }
}
