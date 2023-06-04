/**
 * https://developer.salesforce.com/docs/component-library/bundle/lightning-datatable/example
 */

import {LightningElement, wire} from 'lwc';

import getCustomers from '@salesforce/apex/SearchCustomersController.getCustomers';

const COLUMNS = [
    { label: 'Nome Account', fieldName: 'accountId', type: 'url', typeAttributes: { label: { fieldName: 'accountName' } } },
    { label: 'Nome', fieldName: 'contactId', type: 'url', typeAttributes: { label: { fieldName: 'contactName' } } },
    ...
];

export default class CustomerSearch extends LightningElement {

    searchTerm = '';
    data = [];
    columns = COLUMNS;

    // https://developer.salesforce.com/docs/component-library/documentation/en/lwc/lwc.apex_wire_method
    @wire(getCustomers, {searchTerm: '$searchTerm'})
    loadCustomers({error, data}) {
        if (error) {
            data = [];
            // TODO error handling
            console.log(error);
        } else if (data) {
            this.data = data.map(row => {
                ...
            });
        }
    }

    handleSearch(event) {
        this.searchTerm = event.target.value;
    }
}
