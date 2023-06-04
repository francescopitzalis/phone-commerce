public with sharing class SearchCustomersController {

    public class CustomerDTO {
        @AuraEnabled public Id accountId;
        @AuraEnabled public String accountName;
        @AuraEnabled public Id contactId;
        @AuraEnabled public String contactName;
        @AuraEnabled public Decimal ordersTotal;
        @AuraEnabled public Date accountCreatedDate;
    }

    @AuraEnabled(cacheable=true)
    public static List<CustomerDTO> getCustomers(String searchTerm) {
        List<Contact> contacts = searchContacts(searchTerm);
        List<CustomerDTO> result = buildCustomerDTOs(contacts);
        return result;
    }

    private static List<Contact> searchContacts(String searchTerm) {
        // TODO List<Contact> contacts = [SELECT ... FROM Contact WHERE ...];
        return null;
    }

    private static List<CustomerDTO> buildCustomerDTOs(List<Contact> contacts) {
        List<CustomerDTO> result = new List<CustomerDTO>();
        for (Contact contact : contacts) {
            CustomerDTO dto = buildCustomerDTO(contact);
            result.add(dto);
        }
        return result;
    }

    private static CustomerDTO buildCustomerDTO(Contact contact) {
        CustomerDTO dto = new CustomerDTO();
        // TODO mapping
        return dto;
    }
}
