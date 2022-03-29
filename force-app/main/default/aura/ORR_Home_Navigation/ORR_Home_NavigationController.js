({
    handleNewRegistration : function(component, event, helper) {
        event.preventDefault();  
        var navService = component.find( "navService" );  
        var pageReference = {  
            type: "comm__namedPage",  
            attributes: {  
                pageName: "new-rental"  
            } 
        };  
        sessionStorage.setItem('pageTransfer', JSON.stringify(pageReference.state));  
        navService.navigate(pageReference); 
    },

    handleRequestInspection: function (component, event, helper) {
        component.set('v.isOpen', true);
        console.log('Inside RequestInspection');
        var flow = component.find("flowId");
        flow.startFlow("ORI_Request_Inspection_Flow");
        
    },

    handleRequestReInspection: function (component, event, helper) {
        component.set('v.isOpen', true);
        console.log('Inside Request ReInspection');
        var flow = component.find("flowId");
        flow.startFlow("ORI_Request_Reinspection");
        
    },

    payForRegistration : function(component, event, helper) {
        console.log('Pay clicked');
        component.set("v.isOpen", true);
        var flow = component.find("flowId");
        flow.startFlow("ORR_Pay_Now");
       
    },

    handleOwnershipChange : function(component, event, helper) {
        event.preventDefault();  
        var navService = component.find( "navService" );  
        var pageReference = {  
            type: "comm__namedPage",  
            attributes: {  
                pageName: "ownership-change"  
            } 
        };  
        sessionStorage.setItem('pageTransfer', JSON.stringify(pageReference.state));  
        navService.navigate(pageReference); 
    },
    
    handleRenewal : function(component, event, helper) {
     /*   event.preventDefault();  
        var navService = component.find( "navService" );  
        var pageReference = {  
            type: "comm__namedPage",  
            attributes: {  
                pageName: "renewal"  
            } 
        };  
        sessionStorage.setItem('pageTransfer', JSON.stringify(pageReference.state));  
        navService.navigate(pageReference); */
        console.log('Renewal clicked');
        component.set("v.isOpen", true);
        var flow = component.find("flowId");
        flow.startFlow("ORR_Renewal_Flow");
    },

    closeModalOnFinish : function(component, event, helper) {
        component.set("v.isOpen", false);
    },

    closeModalOnFlow : function(component, event, helper) {
        if(event.getParam('status') === "FINISHED") {
            component.set("v.isOpen", false);
        }
    }
})