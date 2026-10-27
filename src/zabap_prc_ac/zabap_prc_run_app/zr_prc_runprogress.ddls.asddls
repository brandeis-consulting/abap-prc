@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Run Progress and Statistics'
@Metadata.allowExtensions: true

// One row per run: processed objects, objects with error/success header and the
// worst severity - one grouping instead of three views (Nr. 40.2).
// Success = header is not an error (S, W, I), like the list "Processed Objects with
// Success" (MessageSeverity NE E): errors + successes = processed objects (Nr. 40.3).
// A and X are stored as E by the message handler.
// Only objects of a run that have a latest step: inner joins instead of IS NOT INITIAL,
// which 2023 does not support on RAW fields (UUIDs).
define root view entity ZR_PRC_RunProgress
  as select from ZR_PRC_ProcessedObject as ProcessedObject
    inner join   zprc_run                 as Run        on Run.uuid             = ProcessedObject.RunUUID
    inner join   zprc_proc_step           as LatestStep on LatestStep.step_uuid = ProcessedObject.LatestStepUUID
{
  key ProcessedObject.RunUUID,
      count(*)                                                                                                  as AlreadyProcessedObjects,
      cast( sum( case ProcessedObject._LatestStep.MessageSeverity when 'E' then 1 else 0 end ) as abap.int4 )  as NumberOfErrors,
      cast( sum( case ProcessedObject._LatestStep.MessageSeverity when 'E' then 0 else 1 end ) as abap.int4 )  as NumberOfSuccess,
      min( ProcessedObject._LatestStep.MessageSeverityCode )                                                    as WorstMessageSeverityCode
}
group by
  ProcessedObject.RunUUID
