@EndUserText.label: 'Parameter to create a Processed Object'
define root abstract entity ZA_PRC_CreateProcessedObject
{
  runUUID             : sysuuid_x16;
  processName         : zprc_process_name;
  mailAddress         : zprc_mail_address;
  payloadJson         : zprc_payload_json;
  factoryClassName    : zprc_process_impl_class;
  processedObject     : abap.char(50);
  processedObjectUUID : sysuuid_x16;
  doNotProcessBefore  : tzntstmpl;
  queueID             : abap.char(50);
  queuePosition       : abap.int8;
}
