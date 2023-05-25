public with sharing class ProductTriggerHandler extends TriggerHandler {

    private final List<Product__c> newList;
    private final List<Product__c> oldList;
    private final Map<Id, Product__c> newMap;
    private final Map<Id, Product__c> oldMap;

    private ProductTriggerHandler(TriggerOperation op, List<Product__c> newList, List<Product__c> oldList, Map<Id, Product__c> newMap, Map<Id, Product__c> oldMap) {
        super(op);
        this.newList = newList;
        this.oldList = oldList;
        this.newMap = newMap;
        this.oldMap = oldMap;
    }

    public static void handle(TriggerOperation op, List<Product__c> newList, List<Product__c> oldList, Map<Id, Product__c> newMap, Map<Id, Product__c> oldMap) {
        new ProductTriggerHandler(op, newList, oldList, newMap, oldMap).handle();
    }
    public override void beforeInsert() {
        // TODO
    }
}
