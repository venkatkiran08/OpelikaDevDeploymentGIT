({
    init: function (cmp, event, helper) {
        cmp.set("v.isOpen", true);
        cmp.set('v.columns', [
            { label: 'Application ID', fieldName: 'appNumber', type: 'text' },
            { label: 'Location', fieldName: 'location', type: 'text' },
            { label: 'Inspection Date', fieldName: 'inspDate', type: 'date-local' },
            { label: 'Amount', fieldName: 'payAmount', type: 'currency',cellAttributes: { alignment: 'left' } }

        ]);
        helper.getUserType(cmp,event, helper);
        if (!cmp.get("v.ReInspectionChoice")) {
            helper.fetchData(cmp, event, helper);  
        }
        else {
            helper.fetchReinspectionData(cmp, event, helper);
        }
    },
    
    handleClick: function (cmp, event, helper) {
        var isScreen1 = cmp.get("v.isScreen1");
        if (isScreen1) {
            helper.handleScreen1(cmp, event, helper);          
        }
        else {
            helper.handleNext(cmp, event, helper);
        }    
    },

    selectAllCheckbox: function (cmp, event, helper) {
        var selectedHeaderCheck = cmp.find("selectAllId").get("v.checked");
        var updatedAllRecords = [];
        var listOfAllApps = cmp.get("v.filteredData");
        for (var i = 0; i < listOfAllApps.length; i++) {
            // check if header checkbox is 'true' then update all checkbox with true
            // else update all records with false  
            if (selectedHeaderCheck == true) {
                listOfAllApps[i].isChecked = true;
            } else {
                listOfAllApps[i].isChecked = false;
            }
            updatedAllRecords.push(listOfAllApps[i]);
        }
        cmp.set("v.filteredData", updatedAllRecords);
    },

    handlePreviousClick : function(cmp, event, helper) {
        let isPortalUser = cmp.get("v.isPortalUser");
        if(!isPortalUser && cmp.get("v.isScreen1")){
            helper.handlePrevious(cmp, event, helper);
        }
        else{
            if(isPortalUser){
                cmp.set("v.prevFlag", true);
            }
            cmp.set("v.isScreen1", true);
            cmp.set("v.isOpen", true);
            cmp.set("v.isSelected", false); 
        }
       
    },

    searchTable : function(cmp,event,helper) {
        var allRecords = cmp.get("v.data");
        var searchFilter = event.getSource().get("v.value").toUpperCase();
        
        var tempArray = [];
        var i;

        for(i=0; i < allRecords.length; i++){
            if((allRecords[i].appNumber && allRecords[i].appNumber.toUpperCase().indexOf(searchFilter) != -1) ||
               (allRecords[i].location && allRecords[i].location.toUpperCase().indexOf(searchFilter) != -1 ) || 
               (allRecords[i].propertyOwner && allRecords[i].propertyOwner.toUpperCase().indexOf(searchFilter) != -1 ) ||
               (allRecords[i].propertyAgent && allRecords[i].propertyAgent.toUpperCase().indexOf(searchFilter) != -1 ) )
            {
                tempArray.push(allRecords[i]);
            }
        }
        cmp.set("v.filteredData",tempArray);
    } 
});