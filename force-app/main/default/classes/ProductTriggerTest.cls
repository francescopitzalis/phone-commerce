@IsTest
private class ProductTriggerTest {
    @IsTest
    static void checkProductIsKitGrandchild() {
        Product__c kit = new Product__c(Name = 'Kit', Price__c = 10.00);
        insert kit;

        Product__c kitChild = new Product__c(Name = 'Kit Child', Price__c = 10.00, Kit__c = kit.Id);
        insert kitChild;

        try {
            Product__c kitGrandchild = new Product__c(Name = 'Kit Grandchild', Price__c = 10.00, Kit__c = kitChild.Id);
            insert kitGrandchild;
            Assert.fail('Kit Grandchild should not be inserted');
        } catch (DmlException e) {
            Assert.isTrue(e.getMessage().contains('Il prodotto'));
            Assert.isTrue(e.getMessage().contains('impostato come Kit è a sua volta parte di un Kit'));
        }

        Product__c kitGrandchild = new Product__c(Name = 'Kit Grandchild', Price__c = 10.00);
        insert kitGrandchild;

        try {
            kitGrandchild.Kit__c = kitChild.Id;
            update kitGrandchild;
            Assert.fail('Kit Grandchild should not be updated');
        } catch (DmlException e) {
            Assert.isTrue(e.getMessage().contains('Il prodotto'));
            Assert.isTrue(e.getMessage().contains('impostato come Kit è a sua volta parte di un Kit'));
        }
    }

    @IsTest
    static void checkKitIsGrandfather() {
        Product__c kit = new Product__c(Name = 'Kit', Price__c = 10.00);
        insert kit;

        Product__c kitChild = new Product__c(Name = 'Kit Child', Price__c = 10.00, Kit__c = kit.Id);
        insert kitChild;

        Product__c kitFather = new Product__c(Name = 'Kit Father', Price__c = 10.00);
        insert kitFather;

        try {
            kit.Kit__c = kitFather.Id;
            update kit;
            Assert.fail('Kit should not be updated');
        } catch (DmlException e) {
            Assert.isTrue(e.getMessage().contains('Il kit'));
            Assert.isTrue(e.getMessage().contains('non può essere parte di un altro kit'));
        }
    }
}
