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

    @IsTest
    static void setIsKitFlagOnParent() {
        // Insert case
        Product__c kit = new Product__c(Name = 'Kit', Price__c = 10.00);
        insert kit;

        Assert.isFalse([SELECT IsKit__c FROM Product__c WHERE Id = :kit.Id].IsKit__c);

        Product__c kitChild = new Product__c(Name = 'Kit Child', Price__c = 10.00, Kit__c = kit.Id);
        insert kitChild;

        Assert.isTrue([SELECT IsKit__c FROM Product__c WHERE Id = :kit.Id].IsKit__c);

        // Update case
        Product__c kit2 = new Product__c(Name = 'Kit', Price__c = 10.00);
        insert kit2;

        Product__c kitChild2 = new Product__c(Name = 'Kit Child', Price__c = 10.00);
        insert kitChild2;

        Assert.isFalse([SELECT IsKit__c FROM Product__c WHERE Id = :kit2.Id].IsKit__c);

        kitChild2.Kit__c = kit2.Id;
        update kitChild2;

        Assert.isTrue([SELECT IsKit__c FROM Product__c WHERE Id = :kit2.Id].IsKit__c);
    }

    @IsTest
    static void checkManualKitPriceUpdate() {
        Product__c kit = new Product__c(Name = 'Kit', Price__c = 10.00);
        insert kit;

        Product__c kitChild = new Product__c(Name = 'Kit Child', Price__c = 10.00, Kit__c = kit.Id);
        insert kitChild;

        try {
            kit.Price__c = 20.00;
            update kit;
            Assert.fail('Kit should not be updated');
        } catch (DmlException e) {
            Assert.isTrue(e.getMessage().contains('Il prezzo di un kit non può essere modificato manualmente.'));
        }
    }

    @IsTest
    static void updateKitsPrice() {
        Product__c kit = new Product__c(Name = 'Kit', Price__c = 0.00);
        insert kit;

        // Insert case

        Product__c kitChild1 = new Product__c(Name = 'Kit Child 1', Price__c = 10.00, Kit__c = kit.Id);
        insert kitChild1;

        Assert.areEqual(10.00, [SELECT Price__c FROM Product__c WHERE Id = :kit.Id].Price__c);

        Product__c kitChild2 = new Product__c(Name = 'Kit Child 2', Price__c = 20.00, Kit__c = kit.Id);
        insert kitChild2;

        Assert.areEqual(30.00, [SELECT Price__c FROM Product__c WHERE Id = :kit.Id].Price__c);

        // Update price case

        kitChild1.Price__c = 30.00;
        update kitChild1;

        Assert.areEqual(50.00, [SELECT Price__c FROM Product__c WHERE Id = :kit.Id].Price__c);

        // Update kit case

        Product__c kit2 = new Product__c(Name = 'Kit 2', Price__c = 0.00);
        insert kit2;

        Product__c kitChild3 = new Product__c(Name = 'Kit Child 3', Price__c = 10.00, Kit__c = kit2.Id);
        insert kitChild3;

        Assert.areEqual(10.00, [SELECT Price__c FROM Product__c WHERE Id = :kit2.Id].Price__c);

        kitChild1.Kit__c = kit2.Id;
        update kitChild1;

        Assert.areEqual(20.00, [SELECT Price__c FROM Product__c WHERE Id = :kit.Id].Price__c);
        Assert.areEqual(40.00, [SELECT Price__c FROM Product__c WHERE Id = :kit2.Id].Price__c);

        // Delete case

        delete kitChild3;

        Assert.areEqual(30.00, [SELECT Price__c FROM Product__c WHERE Id = :kit2.Id].Price__c);

        // Undelete case

        undelete kitChild3;

        Assert.areEqual(40.00, [SELECT Price__c FROM Product__c WHERE Id = :kit2.Id].Price__c);
    }
}
