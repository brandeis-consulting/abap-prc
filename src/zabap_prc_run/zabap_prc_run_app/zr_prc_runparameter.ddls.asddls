@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Parameter for run'
@Metadata.allowExtensions: true
 
define view entity ZR_PRC_RunParameter as select from zprc_run_params as RunParams
association to parent ZR_PRC_Run as _Run on _Run.UUID = $projection.JobUUID  
{
    key uuid as UUID,
    job_uuid as JobUUID,
    parameter_name as ParameterName,
    operator as Operator,
    sign as Sign,
    low as Low,
    high as High,
    
    _Run
}
