trigger ProductTrigger on Product__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {

    ProductTriggerHandler.handle(Trigger.operationType, Trigger.new, Trigger.old, Trigger.newMap, Trigger.oldMap);
}
