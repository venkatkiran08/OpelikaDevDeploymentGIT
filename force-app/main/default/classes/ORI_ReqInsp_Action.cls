public class ORI_ReqInsp_Action {
    @AuraEnabled
    public static List<IAListWrapper> fetchRecords() {
        Id rentalRecTypeId = IndividualApplication.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Rental_Registration_Application').getRecordTypeId();
        Id ownerRecTypeId = IndividualApplication.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Ownership_Change').getRecordTypeId();
        Id RenewRecTypeId = IndividualApplication.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Renewal').getRecordTypeId();
        
        List<IAListWrapper> IAWrapperFinalList = new List<IAListWrapper>();
        List<IndividualApplication> iaList = [Select Id,Name,Status,Ownership_Changed__c, LocationId__c,LocationId__r.Name, AccountId From IndividualApplication WHERE LocationId__r.Status__c ='Active'  AND (((LocationId__r.Inspection_Status__c = null OR LocationId__r.Inspection_Status__c = 'Passed') AND (LocationId__r.Inspection_Type__c = null OR LocationId__r.Inspection_Type__c = 'Regular Inspection')) OR (LocationId__r.Inspection_Status__c = 'Failed' AND LocationId__r.Inspection_Type__c = 'Complaint based Inspection')) AND Status = 'Completed' AND Ownership_Changed__c = false AND Is_Section_8__c = false AND RecordTypeId IN (:rentalRecTypeId, :ownerRecTypeId, :RenewRecTypeId)  ORDER BY LocationId__c , Name LIMIT 50000];    
        Map<Id, IndividualApplication> finIALocMap = new Map<Id, IndividualApplication>();
        
        Date dtToday = Date.today();
        Integer thisyear = dtToday.year();
        
        Fee_Configuration__mdt feeMdt = [select Active__c, X1st_Inspection_Fee__c FROM Fee_Configuration__mdt WHERE Year__c =: thisyear AND Active__c =: TRUE];
        
        for(IndividualApplication ia: iaList){
            finIALocMap.put(ia.LocationId__c, ia); 
        }
        
        for(Id tmpId: finIALocMap.keyset()){
            IndividualApplication ia = finIALocMap.get(tmpId);
            IAListWrapper inspReqList = new IAListWrapper();
            inspReqList.Id = ia.Id;
            inspReqList.appNumber = ia.Name;
            inspReqList.location = ia.LocationId__r.Name;
            inspReqList.locationId = ia.LocationId__c;
            inspReqList.isChecked = false;
            inspReqList.accountId = ia.AccountId;
            inspReqList.payAmount = feeMdt.X1st_Inspection_Fee__c;
            IAWrapperFinalList.add(inspReqList);
        }
        System.debug('count'+IAWrapperFinalList.size());
        return IAWrapperFinalList;
    }

    @AuraEnabled
    public static List<IAListWrapper> fetchReinspectionRecords() {
        Id rentalRecTypeId = IndividualApplication.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Rental_Registration_Application').getRecordTypeId();
        Id ownerRecTypeId = IndividualApplication.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Ownership_Change').getRecordTypeId();
        Id RenewRecTypeId = IndividualApplication.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Renewal').getRecordTypeId();
        Id opelikaRecTypeId = Schema.SObjectType.Visit.getRecordTypeInfosByDeveloperName().get('Opelika_Rental_Inspection').getRecordTypeId();

        List<IAListWrapper> IAWrapperFinalList = new List<IAListWrapper>();
        List<IndividualApplication> iaList = [Select Id,Name,Status,Ownership_Changed__c, LocationId__c,LocationId__r.Name, AccountId From IndividualApplication WHERE LocationId__r.Status__c ='Active'  AND (LocationId__r.Inspection_Status__c = 'Failed' AND LocationId__r.Inspection_Type__c = 'Regular Inspection') AND Status = 'Completed' AND Ownership_Changed__c = false AND Is_Section_8__c = false AND RecordTypeId IN (:rentalRecTypeId, :ownerRecTypeId, :RenewRecTypeId)  ORDER BY LocationId__c , Name LIMIT 50000];    
        Map<Id, IndividualApplication> finIALocMap = new Map<Id, IndividualApplication>();
        Map<Id, Visit> finVisMap = new Map<Id, Visit>();
        Set<Id> iaIdSet = new Set<Id>();
        Date dtToday = Date.today();
        Integer thisyear = dtToday.year();
        
        Fee_Configuration__mdt feeMdt = [select Active__c, X1st_Inspection_Fee__c, X1st_Reinspection_Fee__c, Subsequent_Reinspection__c FROM Fee_Configuration__mdt WHERE Year__c =: thisyear AND Active__c =: TRUE];
        
        for(IndividualApplication ia: iaList){
            iaIdSet.add(ia.Id);
            finIALocMap.put(ia.LocationId__c, ia); 
        }

        List<Visit> visList = [SELECT Id, Name, Parent_Visit__c, ContextId FROM Visit WHERE ContextId IN :iaIdSet AND RecordTypeId = :opelikaRecTypeId ORDER BY ContextId, Name];

        for(Visit vi: visList){
            finVisMap.put(vi.ContextId, vi);
        }
        System.debug('finVisMap'+ finVisMap);
        for(Id tmpId: finIALocMap.keyset()){
            IndividualApplication ia = finIALocMap.get(tmpId);
            IAListWrapper inspReqList = new IAListWrapper();
            inspReqList.Id = ia.Id;
            inspReqList.appNumber = ia.Name;
            inspReqList.location = ia.LocationId__r.Name;
            inspReqList.locationId = ia.LocationId__c;
            inspReqList.isChecked = false;
            inspReqList.accountId = ia.AccountId;
            if(finVisMap.containsKey(ia.Id)){
                Visit vi = finVisMap.get(ia.Id);
                if(vi.Parent_Visit__c!=null)
                    inspReqList.payAmount = feeMdt.Subsequent_Reinspection__c;
                else{
                    inspReqList.payAmount = feeMdt.X1st_Reinspection_Fee__c;
                }
                inspReqList.parentVisitId = vi.Id;
            }
            System.debug('inspReqList.payAmount'+inspReqList.payAmount);
            IAWrapperFinalList.add(inspReqList);
        }
        System.debug('count'+IAWrapperFinalList.size());
        return IAWrapperFinalList;
    }

    @AuraEnabled
    public static Boolean checkUserType(){
        User userRec= [SELECT id, usertype FROM User WHERE id = :UserInfo.getUserId() LIMIT 1];
        System.debug('==user'+userRec);
        System.debug('==user.type'+userRec.usertype);
        if(userRec.userType != 'PowerCustomerSuccess'){
            return false;
        }
        return true;
    }
    
    @AuraEnabled
    public static IAStatusWrapper handleValidations(List<IAListWrapper> selectRecs, Boolean portalUser ){

        List<String> portalErrIAList = new List<String>();
        List<String> stdErrIAList = new List<String>();
        List<String> noSlotIAList = new List<String>();
        List<String> overSlotIAList = new List<String>();
        Map<Date, Integer> dateSlotMap = new Map<Date, Integer>();
        IAStatusWrapper iasWrap = new IAStatusWrapper();
        Map<Date,Integer> inspDateCountMap =  new Map<Date,Integer>();
        
        for(Inspection_Slot_Config__c inspSlot : [SELECT Id, No_of_Slots__c, Inspection_Date__c, No_of_Available_Slots__c FROM Inspection_Slot_Config__c WHERE No_of_Available_Slots__c > 0]){
            
            dateSlotMap.put(inspSlot.Inspection_Date__c, (Integer) inspSlot.No_of_Available_Slots__c);
            
        }
        if(selectRecs.size()>0){
            
            Map<Date, Integer> tmpMap = new Map<Date, Integer>();
            for(IAListWrapper iaw: selectRecs){
                if (portalUser){
                    if(iaw.inspDate <= Date.today()){
                        portalErrIAList.add(iaw.appNumber);
                    } 
                }
                else{
                    if(iaw.inspDate < Date.today()){
                        stdErrIAList.add(iaw.appNumber);
                    }
                }
                System.debug(iaw.inspDate);
                if(!dateSlotMap.containsKey(iaw.inspDate)){
                    noSlotIAList.add(iaw.appNumber);
                }

                if(tmpMap.containsKey(iaw.inspDate)){
                    tmpMap.put(iaw.inspDate, tmpMap.get(iaw.inspDate)+1);
                }
                else{
                    tmpMap.put(iaw.inspDate, 1);
                }
                if(tmpMap.get(iaw.inspDate) > dateSlotMap.get(iaw.inspDate)){
                    overSlotIAList.add(iaw.appNumber);
                }
            }
        }
        System.debug('===portalErrIAList'+portalErrIAList);
        System.debug('===stdErrIAList'+stdErrIAList);
        System.debug('===noSlotIAList'+noSlotIAList);
        
        if(portalErrIAList.size()>0){
            iasWrap.status =  false;
            iasWrap.message = System.Label.ori_inspection_error1 + ' ' + String.join( portalErrIAList, ', ' );
        }
        
        else if(stdErrIAList.size()>0){
            iasWrap.status =  false;
            iasWrap.message = System.Label.ori_inspection_error2 + ' '+ String.join( stdErrIAList, ', ' );
        }
        
        else if(noSlotIAList.size()>0){
            iasWrap.status =  false;
            iasWrap.message = System.Label.ori_inspection_error3 + ' ' + String.join( noSlotIAList, ', ' );
        }
        
        else if(overSlotIAList.size()>0){
            iasWrap.status =  false;
            iasWrap.message = System.Label.ori_inspection_error3 + ' ' + String.join( overSlotIAList, ', ' );
        }
        
        else{
            iasWrap.status = true;
            iasWrap.message = 'Success';
        }
        
        
        return iasWrap;
    }
    
    
    /* IA wrapper class */  
    public class IAListWrapper {
        @AuraEnabled public boolean isChecked {get;set;}
        @AuraEnabled public String Id {get;set;}
        @AuraEnabled public String parentVisitId {get;set;}
        @AuraEnabled public String appNumber {get;set;}
        @AuraEnabled public String location {get;set;}
        @AuraEnabled public String locationId {get;set;}
        @AuraEnabled public String accountId {get;set;}
        @AuraEnabled public Date inspDate {get;set;}
        @AuraEnabled public Decimal payAmount {get;set;}
        
    }
    
    public class IAStatusWrapper {
        @AuraEnabled public boolean status {get;set;}
        @AuraEnabled public String message {get;set;}
    }
}