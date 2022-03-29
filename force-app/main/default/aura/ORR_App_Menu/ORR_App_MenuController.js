({
	handlePayClick : function(component, event, helper) {
        component.set('v.isOpen', true);
		console.log('Inside payClick');
        var flow = component.find("flowId");
        flow.startFlow("ORR_Pay_Now");
    },
    
    handleRenewal : function(component, event, helper) {
        component.set('v.isOpen', true);
		console.log('Inside RenewalClick');
        var flow = component.find("flowId");
        flow.startFlow("ORR_Renewal_Flow");
    },
    
    handleRequestInspection: function (component, event, helper) {
        component.set('v.isOpen', true);
        console.log('Inside RequestInspection');
        var flow = component.find("flowId");
        flow.startFlow("ORI_Request_Inspection_Flow");
        
    },

    handleRequestReInspection: function (component, event, helper) {
        component.set('v.isOpen', true);
        console.log('Inside Request Re Inspection');
        var flow = component.find("flowId");
        flow.startFlow("ORI_Request_Reinspection");
        
    },
    
    handleNewClick : function(component, event, helper) {
		var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": window.location.origin+'/lightning/cmp/vlocity_ins__vlocityLWCOmniWrapper?c__target=c:propertyInternalUserRegistrationEnglish&c__layout=lightning&c__tabIcon=custom:custom18&c__tabLabel=Rental Registration Form'
        });
        urlEvent.fire();
	},
    handleOwnershipClick : function(component, event, helper) {
		var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": window.location.origin+'/lightning/cmp/vlocity_ins__vlocityLWCOmniWrapper?c__target=c:changeInternalOwnershipRegistrationEnglish&c__layout=lightning&c__tabIcon=custom:custom18&c__tabLabel=Ownership Change Registration Form'
            
        });
        urlEvent.fire();
	},
    
    closeModalOnFinish : function(component, event, helper) {
        if(event.getParam('status') === "FINISHED") {
            component.set("v.isOpen", false);
        }
    },
    
    closeModalOnDeleteFinish : function(component, event, helper) {
        component.set("v.isOpen", false);
    }
})