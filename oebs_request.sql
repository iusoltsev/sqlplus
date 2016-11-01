select distinct fcr.actual_start_date,
                fcr.actual_completion_date,
                user_name,
                user_concurrent_program_name,
                fcp.concurrent_program_name,
                logfile_node_name,
                logfile_name,
                outfile_name,
                oracle_process_id,
                os_process_id
  from apps.fnd_concurrent_requests    fcr,
       apps.fnd_concurrent_programs    fcp,
       apps.fnd_concurrent_programs_tl fcpl,
       apps.fnd_user                   fu
 where request_id = &1
   and fcr.concurrent_program_id = fcp.concurrent_program_id
   and fcr.concurrent_program_id = fcpl.concurrent_program_id
   and fcr.requested_by = fu.user_id
/