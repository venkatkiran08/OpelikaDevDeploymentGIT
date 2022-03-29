@isTest
public class ORI_ReqInsp_ActionTest {
    @isTest
    static void fetchRecordsTest(){
        Id accRecTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        Id iaRecTypeId = IndividualApplication.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Rental_Registration_Application').getRecordTypeId();
        Id ownerRecTypeId = IndividualApplication.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Ownership_Change').getRecordTypeId();
        account acc=new account(RecordTypeID=accRecTypeId,FirstName='Test FName',LastName='Test LName',PersonMailingStreet='test@yahoo.com',PersonMailingPostalCode='12345',PersonMailingCity='SFO',PersonEmail='test@yahoo.com',PersonHomePhone='1234567',PersonMobilePhone='12345678' );
        insert acc;
        account acc1=new account(RecordTypeID=accRecTypeId,FirstName='Test1 FName1',LastName='Test1 LName1',PersonMailingStreet='test1@yahoo.com',PersonMailingPostalCode='123745',PersonMailingCity='33SFO',PersonEmail='test1@yahoo.com',PersonHomePhone='12345678',PersonMobilePhone='123456789' );
        insert acc1;
        RegulatoryAuthorizationType licence=new RegulatoryAuthorizationType(RegulatoryAuthCategory='License',Name='test');
        insert licence;
        
        User user = new User();
        Id ProfileId = [SELECT Id FROM Profile WHERE Name ='System Administrator'].Id;
        user.LastName = 'last';
        user.Email = 'ORRuser000@gmail.com';
        user.Username = 'ORRuser000@gmail.com';
        user.CompanyName = 'TEST';
        user.Title = 'title';
        user.Alias = 'alias';
        user.TimeZoneSidKey = 'America/Los_Angeles';
        user.EmailEncodingKey = 'UTF-8';
        user.LanguageLocaleKey = 'en_US';
        user.LocaleSidKey = 'en_US';
        user.profileId=ProfileId;
        insert user;
        
        
        Schema.Location LocObj = new Schema.Location();
        LocObj.Name ='122 N 20TH ST, 26 Opelika, 36801';
        LocObj.LocationType = 'Apartment';
        LocObj.Status__c = 'Active';
        LocObj.Renewal_Status__c = 'Not Renewed'; 
        insert LocObj;
        
        
        Schema.Location LocObj1 = new Schema.Location();
        LocObj1.Name ='122 N 20TH ST, 27 Opelika, 36801';
        LocObj1.LocationType = 'Apartment';
        LocObj1.Status__c = 'Active';
        LocObj1.Renewal_Status__c = 'Not Renewed'; 
        insert LocObj1;
        
        Schema.Location LocObj2 = new Schema.Location();
        LocObj2.Name ='122 N 20TH ST, 28 Opelika, 36801';
        LocObj2.LocationType = 'Apartment';
        LocObj2.Status__c = 'Active';
        LocObj2.Inspection_Status__c = 'Failed';
        LocObj2.Inspection_Type__c = 'Regular Inspection';
        insert LocObj2;
        
        
        IndividualApplication app=new IndividualApplication(RecordTypeId=iaRecTypeId,accountid=acc.id,LicenseTypeId=licence.id,status='Completed',AppliedDate=system.now(),category='License', AmountPaid = 30,LocationId__c = LocObj.Id,Valid_thru__c = '2021');
        insert app;
        IndividualApplication app1=new IndividualApplication(RecordTypeId=iaRecTypeId,accountid=acc.id,LicenseTypeId=licence.id,status='Completed',AppliedDate=system.now(),category='License', AmountPaid = 30,LocationId__c = LocObj1.Id,Valid_thru__c = '2021');
        insert app1;
        IndividualApplication app2=new IndividualApplication(RecordTypeId=iaRecTypeId,accountid=acc.id,LicenseTypeId=licence.id,status='Completed',AppliedDate=system.now(),category='License', AmountPaid = 30,LocationId__c = LocObj2.Id,Valid_thru__c = '2021');
        insert app2;
        
        InspectionType it = new InspectionType();
        it.Name = 'Regular Inspection';
        insert it;
        
        Visit vi = new Visit();
        vi.PlaceId = LocObj2.Id;
        vi.AccountId = acc.id;
        vi.ContextId = app2.Id;
        vi.VisitTypeId = it.Id;
        Date tDt = System.today();
        vi.PlannedVisitStartTime = Datetime.newInstance(tDt.year(), tDt.month(), tDt.day()+1);
        insert vi;
            
        Boolean userTypeCheck = ORI_ReqInsp_Action.checkUserType();
        System.assertEquals(false, userTypeCheck);
        
        String iaName = [SELECT Name FROM IndividualApplication WHERE Id = :app.Id].Name;
        String iaName1 = [SELECT Name FROM IndividualApplication WHERE Id = :app1.Id].Name;
        
        List<ORI_ReqInsp_Action.IAListWrapper> fetchRecordsList = ORI_ReqInsp_Action.fetchRecords();
        List<ORI_ReqInsp_Action.IAListWrapper> reinspectFetchRecordsList = ORI_ReqInsp_Action.fetchReinspectionRecords();
        
        List<Inspection_Slot_Config__c> slotConfigList = new List<Inspection_Slot_Config__c>{
            new Inspection_Slot_Config__c(No_of_Slots__c=3,No_of_Booked_Slots__c=0,Inspection_Date__c=System.today()),
                new Inspection_Slot_Config__c(No_of_Slots__c=3,No_of_Booked_Slots__c=0,Inspection_Date__c=Date.newInstance(2022, 02, 20)),
                new Inspection_Slot_Config__c(No_of_Slots__c=3,No_of_Booked_Slots__c=0,Inspection_Date__c=Date.newInstance(2022, 03, 10)),
                new Inspection_Slot_Config__c(No_of_Slots__c=1,No_of_Booked_Slots__c=0,Inspection_Date__c=Date.newInstance(2022, 06, 02)),
                new Inspection_Slot_Config__c(No_of_Slots__c=1,No_of_Booked_Slots__c=0,Inspection_Date__c=Date.newInstance(2022, 08, 11))
                };
                    
                    insert slotConfigList;
        
        List<ORI_ReqInsp_Action.IAListWrapper> selectRecsList = new List<ORI_ReqInsp_Action.IAListWrapper>();
        List<Date> testDateList = new List<Date>{Date.newInstance(2022, 02, 20), Date.newInstance(2022, 02, 10), Date.newInstance(2022, 06, 02), Date.newInstance(2022, 06, 02), Date.newInstance(2022, 08, 11)};
            
            ORI_ReqInsp_Action.IAListWrapper iaListWrap0 = fetchRecordsList[0];
        iaListWrap0.inspDate = testDateList[0];
        System.debug('iaListWrap0=='+iaListWrap0);
        selectRecsList.add(iaListWrap0);
        ORI_ReqInsp_Action.IAStatusWrapper finStatus0 = ORI_ReqInsp_Action.handleValidations(selectRecsList, false);
        System.assertEquals(System.Label.ori_inspection_error2 + ' '+iaName, finStatus0.message);
        selectRecsList.clear();
        
        
        ORI_ReqInsp_Action.IAListWrapper iaListWrap1 = fetchRecordsList[0];
        iaListWrap1.inspDate = testDateList[1];
        selectRecsList.add(iaListWrap1);
        ORI_ReqInsp_Action.IAStatusWrapper finStatus1 = ORI_ReqInsp_Action.handleValidations(selectRecsList, false);
        System.assertEquals(System.Label.ori_inspection_error2+' '+iaName, finStatus1.message);
        selectRecsList.clear();
        
        ORI_ReqInsp_Action.IAListWrapper iaListWrap2 = fetchRecordsList[0];
        iaListWrap2.inspDate = testDateList[2];
        selectRecsList.add(iaListWrap2);
        
        ORI_ReqInsp_Action.IAListWrapper iaListWrap3 = fetchRecordsList[1];
        iaListWrap3.inspDate = testDateList[3];
        
        selectRecsList.add(iaListWrap3);
        ORI_ReqInsp_Action.IAStatusWrapper finStatus2 = ORI_ReqInsp_Action.handleValidations(selectRecsList, false);
        System.assertEquals(System.Label.ori_inspection_error3+' '+iaName1, finStatus2.message);
        selectRecsList.clear();
        
        
        ORI_ReqInsp_Action.IAListWrapper iaListWrap4 = fetchRecordsList[0];
        iaListWrap4.inspDate = testDateList[4];
        selectRecsList.add(iaListWrap4);
        ORI_ReqInsp_Action.IAStatusWrapper finStatus4 = ORI_ReqInsp_Action.handleValidations(selectRecsList, false);
        System.assertEquals('Success', finStatus4.message);
        
    }
}