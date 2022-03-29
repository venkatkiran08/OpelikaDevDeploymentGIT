public class ORI_Invocable_RequestInsp{
    
    @InvocableMethod(label='Create Visit Records' description='Return visit inspection records')
    public static List<visitOutputWrapper> createInspection(List<DataWrapper> dataList) { // 
        //throw new MyException('First exception'); 
        System.debug('Test');
        List<IAListWrapper> deserialIARecords = new List<IAListWrapper>();
        List<Visit> visitList = new List<Visit>();
        List<visitOutputWrapper> visitOutputWrapperList = new List<visitOutputWrapper>();
        List<String> newIds = new List<String>();
        
        for(DataWrapper dat : dataList){
            System.debug('dat.iaRecords*** ' + dat.iaRecords);
            deserialIARecords = (List<IAListWrapper>) JSON.deserialize(dat.iaRecords, List<IAListWrapper>.class);
            
            
        }
        
        System.debug('===deserialIARecords'+ deserialIARecords);
        Map<String, InspectionType> inspeTypes = new Map<String, InspectionType>();
        for(InspectionType it : [SELECT Id, Name FROM InspectionType]){
            inspeTypes.put(it.Name, it );
        }
        Id opelikaRecordTypeId = Schema.SObjectType.Visit.getRecordTypeInfosByDeveloperName().get('Opelika_Rental_Inspection').getRecordTypeId();
        if(deserialIARecords.size() > 0){
            
            for(IAListWrapper iaw: deserialIARecords){
                Visit vis = new Visit();
                vis.RecordTypeId = opelikaRecordTypeId;
                vis.PlaceId = iaw.locationId;
                vis.AccountId = iaw.accountId;
                vis.ContextId = iaw.Id;
                Date dt = Date.valueOf(iaw.inspDate);
                //vis.PlannedVisitStartTime = Datetime.valueOf(iaw.inspDate + ' 00:00:00');
                vis.PlannedVisitStartTime = Datetime.newInstance(dt.year(),dt.month(),dt.day(), 23, 59, 00);
                if(dataList[0].complaintType == true){
                    if(inspeTypes.containsKey('Complaint based Inspection'))
                        vis.VisitTypeId = inspeTypes.get('Complaint based Inspection').Id;
                }
                else{
                    if(inspeTypes.containsKey('Regular Inspection'))
                        vis.VisitTypeId =  inspeTypes.get('Regular Inspection').Id;
                }
                if(dataList[0].reInspectionFlag == true){
                    vis.Parent_Visit__c = iaw.parentVisitId;
                }
                visitList.add(vis);
            }
            System.debug('==visitList'+ visitList);
            
            if(visitList.size()>0){
                Database.SaveResult[] results = Database.insert(visitList, true);
                // iterate over the list of returned results
                for(Database.SaveResult result : results) {
                    if(result.isSuccess()) {
                        newIds.add(result.getId());
                        System.debug('Successfully inserted Visits : ' + result.getId());
                    } else {
                        // iterate over the failed ones
                        for(Database.Error error : result.getErrors()) {
                            System.debug('Error Status : ' + error.getStatusCode() + ' : ' + 'Error message : ' + error.getMessage());
                        }
                    }
                }
                if(newIds.size()>0){

                    Map<Id, String> locIdMap = new Map<Id, String>();
                    for(Visit vis: [SELECT Id, PlaceId, VisitType.Name FROM Visit WHERE Id IN :newIds]){
                        locIdMap.put(vis.PlaceId, vis.VisitType.Name);
                    }

                    List<Schema.Location> LocsToUpdate = new List<Schema.Location>();
                    for(Schema.Location Loc:[SELECT Id, Inspection_Status__c FROM Location WHERE Id in :locIdMap.keySet()]){
                        Loc.Inspection_Status__c = 'Planned';
                        Loc.Inspection_Type__c = locIdMap.get(Loc.Id);
                        LocsToUpdate.add(Loc);
                    }
                    if(LocsToUpdate.size()>0){
                        update LocsToUpdate;
                    }

                    visitOutputWrapper vo = new visitOutputWrapper();
                    vo.Id = newIds;
                    visitOutputWrapperList.add(vo);
                }
            }
        }
        return visitOutputWrapperList;
    }
    
    
    /* IA wrapper class */  
    public class IAListWrapper {
        public boolean isChecked;
        public String Id;
        public String parentVisitId;
        public String appNumber;
        public String location;
        public String locationId;
        public String accountId;
        public String inspDate;
        public Decimal payAmount;
    }
    
    public class DataWrapper{
        @InvocableVariable(label='IAListWrapper' description='Pass the IA List')
        public String iaRecords;
        @InvocableVariable(label='Complaint Type' description='Pass Inspection Type')
        public Boolean complaintType; 
        @InvocableVariable(label='Reinspection Flag' description='Pass Reinspection Flag')
        public Boolean reInspectionFlag; 
        
    }
    
    public class visitOutputWrapper {
        @InvocableVariable
        public List<String> Id;
    }
    
    public class MyException extends Exception{
        
    }
}