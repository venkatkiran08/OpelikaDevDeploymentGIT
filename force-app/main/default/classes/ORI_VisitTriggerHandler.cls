public without sharing class ORI_VisitTriggerHandler {
    public static void createActionPlan(List<Visit> newVisits){
        User userRec= [SELECT id, usertype FROM User WHERE id = :UserInfo.getUserId() LIMIT 1];
        System.debug('==user.type'+userRec.usertype);
        if(userRec.userType != 'PowerCustomerSuccess'){
            List<ActionPlan> actionPlanList = new List<ActionPlan>();
            String inspActionTemplateVersion = [SELECT Id FROM ActionPlanTemplateVersion WHERE Name = 'Inspection Template' AND Status = 'Final' LIMIT 1].Id;
            System.debug('inspActionTemplateVersion=='+inspActionTemplateVersion);
            System.debug('newVisits=='+newVisits);
            List<ActionPlan> acPlans = new List<ActionPlan>();
            for(Visit vis : newVisits){
                ActionPlan apRecord = new ActionPlan();
                apRecord.TargetId = vis.Id;
                apRecord.ActionPlanTemplateVersionId = inspActionTemplateVersion;
                apRecord.Name = 'Inspection Action Plan';
                apRecord.ActionPlanType = 'Retail';
                apRecord.ActionPlanState = 'Not Started';
                apRecord.StartDate = Date.valueOf(vis.PlannedVisitStartTime);
                
                actionPlanList.add(apRecord);
            }
            System.debug('actionPlanList=='+actionPlanList);
            
            try{
                insert actionPlanList;
            }
            catch(DmlException e){
                System.debug('Action Plan Error'+ e.getMessage());
            }
        }        
    }
    
    public static void createShareRecords(List<Visit> newVisitList) {
        Set<Id> accountIds = new Set<Id>();
        Map<String,String> accountToUserMap = new Map<String,String>();
        List<Application_Role__c> appRoles = new List<Application_Role__c>();
        Map<Id, List<Id>> iaVisitMap = new Map<Id, List<Id>>();    
        Map<Id, List<Id>> userVisitShareMap = new Map<Id, List<Id>>();
        
        Set<Id> userSet = new Set<Id>();
        Map<Id, Id> visitInspTypeMap = new Map<Id, Id>();
        Map<Id, String> inspeTypes = new Map<Id, String>();
        
        for(InspectionType it : [SELECT Id, Name FROM InspectionType]){
            inspeTypes.put(it.Id, it.Name);
        }
        for(Visit vi : newVisitList){
            visitInspTypeMap.put(vi.Id, vi.VisitTypeId);
            if(iaVisitMap.containsKey(vi.ContextId)) {
                iaVisitMap.get(vi.ContextId).add(vi.Id);
            } else {
                iaVisitMap.put(vi.ContextId, new List<Id> { vi.Id });
            }
        }
        
        system.debug('.>>>newVisitList>'+newVisitList);
        
        for(Application_Role__c ar : [SELECT Id,Agent_Contact__c,role__c,status__c,Agent_Contact__r.Name,Individual_Application__c,Individual_Application__r.OwnerId,Individual_Application__r.RecordType.DeveloperName FROM Application_Role__c WHERE Individual_Application__c IN :iaVisitMap.keyset()]){
            appRoles.add(ar);
            accountIds.add(ar.Agent_Contact__c);
        }
        system.debug('appRoles ==>' +appRoles);
        system.debug('accountIds ==>' +accountIds);
        
        for(User tempUser : [SELECT Id,AccountId FROM User WHERE AccountId IN :accountIds]){
            accountToUserMap.put(tempUser.AccountId,tempUser.Id);
            userSet.add(tempUser.Id);
        }
        
        for(VisitShare vs : [SELECT Id, UserOrGroupId,Parent.Id FROM VisitShare WHERE  UserOrGroupId IN :userSet]){
            if(userVisitShareMap.containsKey(vs.UserOrGroupId)) {
                userVisitShareMap.get(vs.UserOrGroupId).add(vs.ParentId);
            } else {
                userVisitShareMap.put(vs.UserOrGroupId, new List<Id> { vs.ParentId });
            }
        }
        System.debug('userVisitShareMap=='+userVisitShareMap);
        system.debug('accountToUserMap ==>' +accountToUserMap);
        List<VisitShare> visitShareList = new List<VisitShare>();
        for(Application_Role__c appRole : appRoles) {
            if(String.isNotBlank(appRole.Individual_Application__c) && (accountToUserMap.size()>0 && accountToUserMap.containskey(appRole.Agent_Contact__c))  && ((appRole.Status__c == 'Active' && (appRole.Individual_Application__r.RecordType.DeveloperName == 'Rental_Registration_Application' || appRole.Individual_Application__r.RecordType.DeveloperName == 'Renewal')) || (appRole.Status__c == 'Draft' && appRole.Individual_Application__r.RecordType.DeveloperName == 'Ownership_Change')))
            {
                for(Id vId : iaVisitMap.get(appRole.Individual_Application__c)){
                    System.debug('inspeTypes.get(visitInspTypeMap.get(vId))'+inspeTypes.get(visitInspTypeMap.get(vId)));
                    if(inspeTypes.get(visitInspTypeMap.get(vId))!= 'Complaint based Inspection'){
                        if(!userVisitShareMap.containsKey(accountToUserMap.get(appRole.Agent_Contact__c)) || !userVisitShareMap.get(accountToUserMap.get(appRole.Agent_Contact__c)).contains(vId)){
                            VisitShare vshr = new VisitShare();
                            vshr.ParentId = vId;
                            vshr.AccessLevel = 'Edit';
                            vshr.RowCause = Schema.VisitShare.RowCause.Manual;
                            vshr.UserOrGroupId = accountToUserMap.get(appRole.Agent_Contact__c);
                            system.debug('vshr ==>' +vshr);
                            visitShareList.add(vshr);
                        }                       
                    }
                }                
            }           
        }
        system.debug('visitShareList ==>' +visitShareList);
        if(visitShareList.size() > 0 && visitShareList != null){
            upsert visitShareList;
        }
    } 
    
    public static void updateHandler(Map<Id, Visit> newRecords, Map<Id, Visit> oldRecords) {
        
        Map<Id, String> locUpdateMap = new Map<Id, String>();
        Map<Id, Visit> newVisitMap = new Map<Id, Visit>();
        
        System.debug('newRecords'+newRecords);
        System.debug('oldRecords'+ oldRecords);
        for(Visit vi : newRecords.values()){
            Visit oldRec = oldRecords.get(vi.Id);
            if(vi.Inspection_Outcome__c != oldRec.Inspection_Outcome__c && vi.Inspection_Outcome__c != null){
                locUpdateMap.put(vi.PlaceId, vi.Inspection_Outcome__c);
            }
            if(vi.VisitorId != oldRec.VisitorId && vi.VisitorId != null){
                newVisitMap.put(vi.Id, vi);
            }
        }
        System.debug('newVisitMap=='+newVisitMap);
        
        System.debug('locUpdateMap=='+locUpdateMap);
        List<Schema.Location> LocsToUpdate = new List<Schema.Location>();
        if(locUpdateMap.keySet().size()>0){
            for(Schema.Location Loc:[SELECT Id, Inspection_Status__c FROM Location WHERE Id in :locUpdateMap.keySet()]){
                Loc.Inspection_Status__c = locUpdateMap.get(Loc.Id);
                LocsToUpdate.add(Loc);
            }
            System.debug('LocsToUpdate'+LocsToUpdate);
            if(LocsToUpdate.size()>0){
                update LocsToUpdate;
            }
        }
        if(newVisitMap.keySet().size()>0){
            Map<Id,Id> actionVisitMap = new Map<Id, Id>();
            List<Visit> newVisitList = new List<Visit>();
            for(ActionPlan ap : [SELECT Id, TargetId FROM ActionPlan WHERE TargetId IN :newVisitMap.keySet()]){
                actionVisitMap.put(ap.TargetId, ap.Id);
            }
            System.debug('actionVisitMap=='+ actionVisitMap);
            for(Id viId : newVisitMap.keySet()){
                if(!actionVisitMap.containsKey(viId)){
                    newVisitList.add(newVisitMap.get(viId));
                }   
            }
            System.debug('newVisitList=='+newVisitList);
            if(newVisitList.size() >0){
                createActionPlan(newVisitList); 
            }
        }
    }
}