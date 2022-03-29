@isTest
public with sharing class ORI_VisitTriggerHandlerTest {
    static testMethod void testManualShareRcords(){
        List<User> users = [SELECT Id,AccountId FROM User WHERE AccountId !=null AND IsActive = true  LIMIT 2];
        Id User1Id = users[0].Id;
        Id User2Id = users[1].Id;
        Id accId = users[0].AccountId;
        System.debug('Users=='+users);
        
        RegulatoryAuthorizationType tempObj = new RegulatoryAuthorizationType();
        tempObj.Name = 'Rental Registration';
        insert tempObj;
        
        Schema.Location LocObj1 = new Schema.Location();
        LocObj1.Name ='122 N 20TH ST, 27 Opelika, 36801';
        LocObj1.LocationType = 'Apartment';
        LocObj1.Status__c = 'Active';
        LocObj1.Renewal_Status__c = 'Not Renewed'; 
        insert LocObj1;
        
        IndividualApplication app = new IndividualApplication();
        app.Category = 'License';
        app.OwnerId = user2Id;
        app.LicenseTypeId = tempObj.Id;
        Id tempAppId = Schema.SObjectType.IndividualApplication.getRecordTypeInfosByDeveloperName().get('Rental_Registration_Application').getRecordTypeId();
        app.RecordTypeId = tempAppId;
        app.AppliedDate = system.now();
        app.LocationId__c = LocObj1.Id;
        
        insert app;
        
        
        List<Application_Role__c> arrList = new List<Application_Role__c>();
        Application_Role__c arr = new Application_Role__c();
        arr.Status__c = 'Active';
        arr.Individual_Application__c  = app.id;
        arr.Agent_Contact__c = accId;
        arr.Role__c = 'Property Agent';
        arrList.add(arr);
        
        insert arrList;
        
        InspectionType it = new InspectionType();
        it.Name = 'Regular Inspection';
        insert it;
                ActionPlanTemplate apt = new ActionPlanTemplate();
        apt.Name = 'Inspection Template';
        apt.ActionPlanType = 'Retail';
        apt.TargetEntityType = 'Visit';
        
        System.debug('before ActionPlanTemplate insert');        
        insert apt;
        
        ActionPlanTemplateVersion aptv = [select Id, Status from ActionPlanTemplateVersion where Status = 'Draft' and
                                          ActionPlanTemplateId = :apt.Id];
        
        
        ActionPlanTemplateItem apti = new ActionPlanTemplateItem(); 
        apti.ActionPlanTemplateVersionId = aptv.Id; 
        apti.Name = 'AP_Teamplate_Item_Apex'; 
        apti.ItemEntityType = 'Task'; 
        insert apti; 
        
        aptv.Status = 'Draft';
        System.debug('before ActionPlanTemplateVersion update');   
        update aptv;
        
        ActionPlanTemplateItemValue aptiv=new ActionPlanTemplateItemValue();
        aptiv.ActionPlanTemplateItemId=apti.id;
        aptiv.ItemEntityFieldName='Task.ActivityDate';
        aptiv.Name=  'ActivityDate';
        aptiv.ValueFormula =' StartDate + 360';
        insert aptiv;
        
        aptv.Status = 'Final';
        System.debug('before ActionPlanTemplateVersion update'); 
        update aptv;
        
        
        Visit vis = new Visit();
        vis.PlaceId =  LocObj1.Id;
        vis.AccountId = accId;
        vis.ContextId = app.Id;
        vis.PlannedVisitStartTime = datetime.newInstance(2024, 9, 15, 12, 30, 0);
        vis.VisitTypeId =  it.Id;      
        insert vis; 
        
        List<VisitShare> vShrs = [SELECT Id, UserOrGroupId, AccessLevel,RowCause FROM VisitShare WHERE ParentId = :vis.Id];
        System.assertEquals(vShrs.size(), 1);
        
        vis.VisitorId = User1Id;
        vis.Inspection_Outcome__c = 'Passed';
        update vis;
    }
    
    
}