trigger ORI_VisitTrigger on Visit (after insert, after update) {
    if(ApexTriggerSwitch.getMetadata('ORI_VisitTrigger').isActive__c){
        if(Trigger.isAfter && Trigger.isInsert){
            ORI_VisitTriggerHandler.createShareRecords(trigger.new);
        }
        if(Trigger.isAfter && Trigger.isUpdate){
            System.debug('After update trigger');
            ORI_VisitTriggerHandler.updateHandler(trigger.newMap, trigger.oldMap);
        }

    }
}