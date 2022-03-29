@isTest
public class ORI_Invocable_RequestInspTest {
    @isTest
    static void createInspectionTest(){
        Id accRecTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        Id iaRecTypeId = IndividualApplication.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Rental_Registration_Application').getRecordTypeId();
        Id ownerRecTypeId = IndividualApplication.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Ownership_Change').getRecordTypeId();
        account acc=new account(RecordTypeID=accRecTypeId,FirstName='Test FName',LastName='Test LName',PersonMailingStreet='test@yahoo.com',PersonMailingPostalCode='12345',PersonMailingCity='SFO',PersonEmail='test@yahoo.com',PersonHomePhone='1234567',PersonMobilePhone='12345678' );
        insert acc;
        
        RegulatoryAuthorizationType licence=new RegulatoryAuthorizationType(RegulatoryAuthCategory='License',Name='test');
        insert licence;
        
        Schema.Location LocObj = new Schema.Location();
        LocObj.Name ='122 N 20TH ST, 26 Opelika, 36801';
        LocObj.LocationType = 'Apartment';
        LocObj.Status__c = 'Active';
        LocObj.Renewal_Status__c = 'Not Renewed'; 
        insert LocObj;
        
        IndividualApplication app=new IndividualApplication(RecordTypeId=iaRecTypeId,accountid=acc.id,LicenseTypeId=licence.id,status='Completed',AppliedDate=system.now(),category='License', AmountPaid = 30,LocationId__c = LocObj.Id,Valid_thru__c = '2021');
        insert app;
        
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
        
        InspectionType it = new InspectionType();
        it.Name = 'Regular Inspection';
        insert it;
            
        InspectionType it1 = new InspectionType();
        it1.Name = 'Complaint based Inspection';
        insert it1;
        
        IndividualApplication iaRec = [SELECT Id, Name, LocationId__c, AccountId, AmountPaid FROM IndividualApplication WHERE Id = :app.Id LIMIT 1];
        ORI_Invocable_RequestInsp.DataWrapper dtWrap = new ORI_Invocable_RequestInsp.DataWrapper();
        
        ORI_Invocable_RequestInsp.IAListWrapper iawrap = new ORI_Invocable_RequestInsp.IAListWrapper();
        iawrap.locationId = iaRec.LocationId__c;
        iawrap.payAmount = iaRec.AmountPaid;
        iawrap.inspDate = '2022-08-24';
        iawrap.accountId = iaRec.AccountId;
        iawrap.Id = iaRec.Id;
        iawrap.appNumber = iaRec.Name;
        
        dtWrap.iaRecords = JSON.serialize(new List<ORI_Invocable_RequestInsp.IAListWrapper>{iawrap});
        System.debug('iawrap'+iawrap);
        System.debug('Serialiawrap'+JSON.serialize(iawrap));
        ORI_Invocable_RequestInsp.createInspection(new List<ORI_Invocable_RequestInsp.DataWrapper>{dtWrap});
        
        System.assertEquals(1, [SELECT Id, Name FROM Visit].size());
        
        dtWrap.complaintType = true;
        
        ORI_Invocable_RequestInsp.createInspection(new List<ORI_Invocable_RequestInsp.DataWrapper>{dtWrap});
        System.assertEquals('Complaint based Inspection', [SELECT VisitType.Name FROM Visit WHERE VisitType.Name = 'Complaint based Inspection'].VisitType.Name);
    }
    
}