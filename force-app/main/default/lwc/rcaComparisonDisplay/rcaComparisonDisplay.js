import { LightningElement, api } from 'lwc';

export default class RcaComparisonDisplay extends LightningElement {
    @api comparisonSections = [];
    @api quote1Name = 'Quote 1';
    @api quote2Name = 'Quote 2';

    /**
     * Handle back button click
     */
    handleBack() {
        // Dispatch back event to parent
        const backEvent = new CustomEvent('back');
        this.dispatchEvent(backEvent);
    }

    /**
     * Handle close button click
     */
    handleClose() {
        // Dispatch close event to parent
        const closeEvent = new CustomEvent('close');
        this.dispatchEvent(closeEvent);
    }

    /**
     * Check if there are sections to display
     */
    get hasSections() {
        return this.comparisonSections && this.comparisonSections.length > 0;
    }
}
