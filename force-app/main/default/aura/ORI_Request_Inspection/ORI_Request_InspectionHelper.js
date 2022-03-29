({
    fetchData: function (cmp, event, helper) {
        cmp.set("v.startLoading", true);
        console.log("spinner on");
        var action = cmp.get("c.fetchRecords");
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                cmp.set("v.startLoading", false);
                cmp.set("v.data", response.getReturnValue());
                cmp.set("v.filteredData", response.getReturnValue());
                console.log('data::: ' + JSON.stringify(cmp.get("v.data")));
            }
            else {
                var errors = response.getError();
                console.log('==errors==>' + JSON.stringify(errors)); 
            }
        });
        $A.enqueueAction(action);
        
    },

    fetchReinspectionData: function (cmp, event, helper) {
        cmp.set("v.startLoading", true);
        console.log("spinner on");
        var action = cmp.get("c.fetchReinspectionRecords");
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                cmp.set("v.startLoading", false);
                cmp.set("v.data", response.getReturnValue());
                cmp.set("v.filteredData", response.getReturnValue());
                console.log('Re inspection data::: ' + JSON.stringify(cmp.get("v.data")));
            }
            else {
                var errors = response.getError();
                console.log('==errors==>' + JSON.stringify(errors)); 
            }
        });
        $A.enqueueAction(action);
        
    },

    getUserType: function (cmp, event, helper) {
        cmp.set("v.startLoading", true);
        console.log("spinner on");
        var action = cmp.get("c.checkUserType");
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                cmp.set("v.startLoading", false);
                cmp.set("v.isPortalUser", response.getReturnValue());
                cmp.set("v.prevFlag", response.getReturnValue());
                console.log('isPortalUser'+response.getReturnValue());
            }
            else {
                var errors = response.getError();
                console.log('==errors==>' + JSON.stringify(errors)); 
            }
        });
        $A.enqueueAction(action);
        
    },
    
    handleScreen1 : function(cmp, event, helper)
    {
        console.log('validations');
        var allRecords = cmp.get("v.filteredData");
        var selectedRecords = [];
        var selectedRecordsSerial = [];
        var errTextList = [];
        let sum = 0;
        for (var i = 0; i < allRecords.length; i++) {
            if (allRecords[i].isChecked) {
                selectedRecords.push(allRecords[i]);
                //selectedRecordsSerial.push(JSON.stringify(allRecords[i]));
                
                if (allRecords[i].inspDate == undefined || allRecords[i].inspDate == null) {
                    errTextList.push(allRecords[i].appNumber);                    
                }
                sum += allRecords[i].payAmount != undefined ? allRecords[i].payAmount : 0;
            }
        }
        cmp.set("v.chargeAmount", sum);
        cmp.set("v.passToFlowData", JSON.stringify(selectedRecords));
        console.log(cmp.get("v.passToFlowData"));

        console.log('selectedRecords.length**** ' + selectedRecords.length);
        console.log('cmp.get("v.ComplaintInspectionChoice")**** ' +cmp.get("v.ComplaintInspectionChoice"));

         if (selectedRecords.length > 1 && cmp.get("v.ComplaintInspectionChoice")) {
            this.showToast("Cannot select more than one application at a time for Complaint based inspections", 'error');            
        }

        else if (selectedRecords.length == 0) {
            this.showToast("Please select atleast one application to proceed", 'error');            
        }

        else if(errTextList.length > 0){
            this.showToast($A.get("$Label.c.ori_inspection_error0")+' '+ errTextList.join(', '), 'error');
        }   
        else {
            cmp.set("v.startLoading", true);
            var action = cmp.get("c.handleValidations");
            console.log(cmp.get("v.isPortalUser"));
            action.setParams({
                selectRecs: selectedRecords,
                portalUser: cmp.get("v.isPortalUser")
            });
            action.setCallback(this, function(response){
                var state = response.getState();
                if (state === "SUCCESS") {
                    var validatedData = response.getReturnValue();
                    cmp.set("v.startLoading", false);
                    console.log(validatedData);
                    if (!validatedData.status) {
                        this.showToast( validatedData.message, 'error');
                    }
                    else {
                        cmp.set("v.selectedData", selectedRecords);
                        cmp.set("v.isOpen", false);
                        cmp.set("v.isScreen1", false);
                        cmp.set("v.isSelected", true);
                        cmp.set("v.prevFlag", false);
                        if(cmp.get('v.ComplaintInspectionChoice')){
                            cmp.set('v.isSelected', false);
                            helper.handleNext(cmp, event, helper);
                        }
                    }
                console.log("success");
                }
                else {
                    var errors = response.getError();
                    console.log('==errors==>' + JSON.stringify(errors)); 
                }
        });
        $A.enqueueAction(action);
        }

    },

    handleNext : function(cmp, event, helper)
    {
        console.log('NEXT Click');
        var response = event.getSource().getLocalId();
        cmp.set("v.value", response);
        var navigate = cmp.get("v.navigateFlow");
        navigate("NEXT");

    },

    handlePrevious : function(cmp, event, helper)
    {
        console.log('Previous Click');
        var response = event.getSource().getLocalId();
        cmp.set("v.value", response);
        var navigate = cmp.get("v.navigateFlow");
        console.log(cmp.get("v.navigateFlow"));
        navigate("BACK");

    },
    
    showToast : function(message, type)
    {
        var toastEvent = $A.get("e.force:showToast");      
        toastEvent.setParams
        ({
            message,
            duration: 2000,
            type
        });
        toastEvent.fire();
    }
});