@EndUserText.label: 'Parameter to initiate the run'
define root abstract entity ZA_PRC_InitiateRunParameter
{
  @UI.hidden: true
  selectOptionString : abap.string(100000);
  
  jobName : abap.char(120);
  
  // Name of the Application Job Template - used to schedule the job generically
  jobTemplateName : abap.char(30);
  
  applicationName : zprc_run_app_name;
}
