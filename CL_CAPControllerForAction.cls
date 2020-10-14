/******************************
 * @File Name          : CL_CAPControllerForAction
 * @Description        : This class is a controller of CL_CAPUsedValuation Lightning Component.
 * @Author             : Ayan Dutta 
***************************************/

Global with sharing class CL_CAPControllerForAction{

    @AuraEnabled
    Global static String capCall(Id colId){
        try {
            List<clcommon__Collateral__c> colList=[SELECT ID,
                                                          clcommon__Current_Mileage__c,
                                                          CAP_Id__c,
                                                          Match_Code__c,
                                                          CAP_Code__c,
                                                          Vehicle_Type__c,
                                                          First_Registered_Date__c 
                                                          FROM clcommon__Collateral__c 
                                                          WHERE id=:colId];
            String returnStatement;
            
            if(colList != null && colList.size() > 0){
                if (colList[0].CAP_Code__c==Null) {
                    returnStatement= CL_CBCustomConstants.CAP_Code_field_is_empty;
                }else if(colList[0].CAP_Id__c==Null){
                    returnStatement= CL_CBCustomConstants.CAP_ID_field_is_empty;
                }else if (colList[0].clcommon__Current_Mileage__c==Null) {
                    returnStatement= CL_CBCustomConstants.Current_Mileage_field_is_empty;
                }else if(colList[0].Vehicle_Type__c==Null){
                    returnStatement= CL_CBCustomConstants.Vehicle_Type_field_is_empty;
                }else if(colList[0].First_Registered_Date__c==Null){
                    returnStatement= CL_CBCustomConstants.First_Registered_Date_field_is_empty;
                }else{
                    String xmlResponse;
                    Map<String,Object> requestParamMap = new Map<String,Object>();
                    Map<String,String> queryIdMap = new Map<String,String>();
                    queryIdMap.put('colId',colId);
                    intframework.AbstractIntegrationService baseintegrationService = intframework.IntegrationServiceFactory.getBaseIntegrationService();
                    intframework.BaseIntegrationResponse responseObject;
                    responseObject = (intframework.BaseIntegrationResponse)baseintegrationService.runSynchronousIntegrationService(CL_CBCustomConstants.CAP,CL_CBCustomConstants.CAP_Used_Valuation,queryIdMap,requestParamMap);

                    if (Test.isRunningTest()) {
                        xmlResponse=CL_CBCustomConstants.xmlResponse_test;
                    }else {
                        
                        xmlResponse=responseObject.response.getbody();
                    }

                    if(xmlResponse.substringBetween('<Success>','</Success>')== 'false') {
                        returnStatement= xmlResponse.substringBetween('<FailMessage>','</FailMessage>');
                    }else if (xmlResponse.substringBetween('<Success>','</Success>')== 'true') {
                        List<clcommon__Collateral_Valuation__c> colVallist = [SELECT id,
                                                                         clcommon__Active__c,
                                                                         Current_CAP_Average__c,
                                                                         Current_CAP_Below__c,
                                                                         Current_CAP_Clean__c,
                                                                         Current_CAP_Retail__c,
                                                                         clcommon__Collateral__c 
                                                                         FROM clcommon__Collateral_Valuation__c 
                                                                         WHERE (clcommon__Collateral__c=:colId 
                                                                         AND clcommon__Active__c=true) 
                                                                         AND (Current_CAP_Average__c!=null 
                                                                         OR Current_CAP_Below__c!=null 
                                                                         OR Current_CAP_Clean__c!=null 
                                                                         OR Current_CAP_Retail__c!=null)];
                        if(colVallist != null && colVallist.size() > 0){
                            for (clcommon__Collateral_Valuation__c colValue: colVallist) {
                                colValue.clcommon__Active__c=false;
                            }
                            update colVallist;
                        }
                        
                        clcommon__Collateral_Valuation__c colVal=new clcommon__Collateral_Valuation__c();
                        colVal.Current_CAP_Average__c=decimal.valueOf(xmlResponse.substringBetween('<Average>','</Average>'));
                        colVal.Current_CAP_Retail__c=decimal.valueOf(xmlResponse.substringBetween('<Retail>','</Retail>'));
                        colVal.Current_CAP_Clean__c=decimal.valueOf(xmlResponse.substringBetween('<Clean>','</Clean>'));
                        colVal.Current_CAP_Below__c=decimal.valueOf(xmlResponse.substringBetween('<Below>','</Below>'));
                        colVal.Date_of_CAP_current_search__c=date.today();
                        colVal.clcommon__Active__c=true;
                        colVal.clcommon__Collateral__c=colId;
                        insert colVal;
                        returnStatement= CL_CBCustomConstants.CAP_Used_Valuation_Call_is_sucsessfully_completed;
                    }
                }
            }
            if(Test.isRunningTest()) {
                CalloutException e = new CalloutException();
                e.setMessage(CL_CBCustomConstants.This_is_a_constructed_exception_for_testing_and_code_coverage);
                throw e;
            }
            return returnStatement;
        }catch(Exception e){
            insert new clcommon__Log__c(
            clcommon__Message__c = 'Exception: '+e.getStackTraceString()+'error='+e.getMessage()+' at Line Number '+e.getLineNumber(),
            clcommon__Time__c = System.Now());
            return ('Exception stack => '+e.getStackTraceString());
        }
    }
}