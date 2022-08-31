USE [msdb]
GO

/****** Object:  Job [Sync SSAS DB]    Script Date: 7/29/2022 12:35:30 AM ******/
EXEC msdb.dbo.sp_delete_job @job_id=N'b6dc4e6c-4644-47a3-9e6d-f382470505f6', @delete_unused_schedule=1
GO

/****** Object:  Job [Sync SSAS DB]    Script Date: 7/29/2022 12:35:30 AM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 7/29/2022 12:35:30 AM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Sync SSAS DB', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=3, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'POWERBI\dan.nguyen', 
		@notify_email_operator_name=N'vnDan', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Sync ParlayCube]    Script Date: 7/29/2022 12:35:30 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Sync ParlayCube', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'ANALYSISCOMMAND', 
		@command=N'
<Synchronize xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns="http://schemas.microsoft.com/analysisservices/2003/engine">
  <Source>
    <ConnectionString>Provider=MSOLAP.8;Data Source=SSAS03\SSASTABULAR;Integrated Security=SSPI;Initial Catalog=ParlayCube</ConnectionString>
    <Object>
      <DatabaseID>ParlayCube</DatabaseID>
    </Object>
  </Source>
  <SynchronizeSecurity>CopyAll</SynchronizeSecurity>
  <ApplyCompression>true</ApplyCompression>
</Synchronize>', 
		@server=N'SSAS02\SSASTABULAR', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Sync EsportCube]    Script Date: 7/29/2022 12:35:30 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Sync EsportCube', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'ANALYSISCOMMAND', 
		@command=N'
<Synchronize xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns="http://schemas.microsoft.com/analysisservices/2003/engine">
  <Source>
    <ConnectionString>Provider=MSOLAP.8;Data Source=SSAS03\SSASTABULAR;Integrated Security=SSPI;Initial Catalog=EsportCube</ConnectionString>
    <Object>
      <DatabaseID>EsportCube</DatabaseID>
    </Object>
  </Source>
  <SynchronizeSecurity>CopyAll</SynchronizeSecurity>
  <ApplyCompression>true</ApplyCompression>
</Synchronize>', 
		@server=N'SSAS02\SSASTABULAR', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Sync NonsportCube]    Script Date: 7/29/2022 12:35:30 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Sync NonsportCube', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'ANALYSISCOMMAND', 
		@command=N'
<Synchronize xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns="http://schemas.microsoft.com/analysisservices/2003/engine">
  <Source>
    <ConnectionString>Provider=MSOLAP.8;Data Source=SSAS03\SSASTABULAR;Integrated Security=SSPI;Initial Catalog=NonsportCube</ConnectionString>
    <Object>
      <DatabaseID>NonsportCube</DatabaseID>
    </Object>
  </Source>
  <SynchronizeSecurity>CopyAll</SynchronizeSecurity>
  <ApplyCompression>true</ApplyCompression>
</Synchronize>', 
		@server=N'SSAS02\SSASTABULAR', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Sync AllProductsCube]    Script Date: 7/29/2022 12:35:30 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Sync AllProductsCube', 
		@step_id=4, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'ANALYSISCOMMAND', 
		@command=N'
<Synchronize xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns="http://schemas.microsoft.com/analysisservices/2003/engine">
  <Source>
    <ConnectionString>Provider=MSOLAP.8;Data Source=SSAS03\SSASTABULAR;Integrated Security=SSPI;Initial Catalog=AllProductsCube</ConnectionString>
    <Object>
      <DatabaseID>AllProductsCube</DatabaseID>
    </Object>
  </Source>
  <SynchronizeSecurity>CopyAll</SynchronizeSecurity>
  <ApplyCompression>true</ApplyCompression>
</Synchronize>', 
		@server=N'SSAS02\SSASTABULAR', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Sync LAP_PerformanceCube]    Script Date: 7/29/2022 12:35:30 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Sync LAP_PerformanceCube', 
		@step_id=5, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'ANALYSISCOMMAND', 
		@command=N'
<Synchronize xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns="http://schemas.microsoft.com/analysisservices/2003/engine">
  <Source>
    <ConnectionString>Provider=MSOLAP.8;Data Source=SSAS03\SSASTABULAR;Integrated Security=SSPI;Initial Catalog=LAP_PerformanceCube</ConnectionString>
    <Object>
      <DatabaseID>LAP_PerformanceCube_UAT</DatabaseID>
    </Object>
  </Source>
  <SynchronizeSecurity>CopyAll</SynchronizeSecurity>
  <ApplyCompression>true</ApplyCompression>
</Synchronize>', 
		@server=N'SSAS02\SSASTABULAR', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Sync TeamsPerformanceCube]    Script Date: 7/29/2022 12:35:30 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Sync TeamsPerformanceCube', 
		@step_id=6, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'ANALYSISCOMMAND', 
		@command=N'
<Synchronize xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns="http://schemas.microsoft.com/analysisservices/2003/engine">
  <Source>
    <ConnectionString>Provider=MSOLAP.8;Data Source=SSAS03\SSASTABULAR;Integrated Security=SSPI;Initial Catalog=TeamsPerformanceCube</ConnectionString>
    <Object>
      <DatabaseID>TeamsPerformanceCube</DatabaseID>
    </Object>
  </Source>
  <SynchronizeSecurity>CopyAll</SynchronizeSecurity>
  <ApplyCompression>true</ApplyCompression>
</Synchronize>', 
		@server=N'SSAS02\SSASTABULAR', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Sync MemberPerformanceCube]    Script Date: 7/29/2022 12:35:30 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Sync MemberPerformanceCube', 
		@step_id=7, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'ANALYSISCOMMAND', 
		@command=N'
<Synchronize xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns="http://schemas.microsoft.com/analysisservices/2003/engine">
  <Source>
    <ConnectionString>Provider=MSOLAP.8;Data Source=SSAS03\SSASTABULAR;Integrated Security=SSPI;Initial Catalog=MemberPerformanceCube</ConnectionString>
    <Object>
      <DatabaseID>MemberPerformanceCube</DatabaseID>
    </Object>
  </Source>
  <SynchronizeSecurity>CopyAll</SynchronizeSecurity>
  <ApplyCompression>true</ApplyCompression>
</Synchronize>', 
		@server=N'SSAS02\SSASTABULAR', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Sync LicHourlyMarketingCube]    Script Date: 7/29/2022 12:35:30 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Sync LicHourlyMarketingCube', 
		@step_id=8, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'ANALYSISCOMMAND', 
		@command=N'
<Synchronize xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns="http://schemas.microsoft.com/analysisservices/2003/engine">
  <Source>
    <ConnectionString>Provider=MSOLAP.8;Data Source=SSAS03\SSASTABULAR;Integrated Security=SSPI;Initial Catalog=LicHourlyMarketingCube</ConnectionString>
    <Object>
      <DatabaseID>LicHourlyMarketingCube</DatabaseID>
    </Object>
  </Source>
  <SynchronizeSecurity>CopyAll</SynchronizeSecurity>
  <ApplyCompression>true</ApplyCompression>
</Synchronize>', 
		@server=N'SSAS02\SSASTABULAR', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Sync HourlyPerformanceCube]    Script Date: 7/29/2022 12:35:30 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Sync HourlyPerformanceCube', 
		@step_id=9, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'ANALYSISCOMMAND', 
		@command=N'
<Synchronize xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns="http://schemas.microsoft.com/analysisservices/2003/engine">
  <Source>
    <ConnectionString>Provider=MSOLAP.8;Data Source=SSAS03\SSASTABULAR;Integrated Security=SSPI;Initial Catalog=HourlyPerformanceCube</ConnectionString>
    <Object>
      <DatabaseID>HourlyPerformanceCube</DatabaseID>
    </Object>
  </Source>
  <SynchronizeSecurity>CopyAll</SynchronizeSecurity>
  <ApplyCompression>true</ApplyCompression>
</Synchronize>', 
		@server=N'SSAS02\SSASTABULAR', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Sync LAPSportbook_PerformanceCube]    Script Date: 7/29/2022 12:35:30 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Sync LAPSportbook_PerformanceCube', 
		@step_id=10, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'ANALYSISCOMMAND', 
		@command=N'
<Synchronize xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns="http://schemas.microsoft.com/analysisservices/2003/engine">
  <Source>
    <ConnectionString>Provider=MSOLAP.8;Data Source=SSAS03\SSASTABULAR;Integrated Security=SSPI;Initial Catalog=LAPSportbook_PerformanceCube</ConnectionString>
    <Object>
      <DatabaseID>LAPSportbook_PerformanceCube</DatabaseID>
    </Object>
  </Source>
  <SynchronizeSecurity>CopyAll</SynchronizeSecurity>
  <ApplyCompression>true</ApplyCompression>
</Synchronize>', 
		@server=N'SSAS02\SSASTABULAR', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Sync VoidPerformance]    Script Date: 7/29/2022 12:35:30 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Sync VoidPerformance', 
		@step_id=11, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'ANALYSISCOMMAND', 
		@command=N'<Synchronize xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns="http://schemas.microsoft.com/analysisservices/2003/engine">
  <Source>
    <ConnectionString>Provider=MSOLAP.8;Data Source=SSAS03\SSASTABULAR;Integrated Security=SSPI;Initial Catalog=VoidPerformanceCube</ConnectionString>
    <Object>
      <DatabaseID>VoidPerformanceCube</DatabaseID>
    </Object>
  </Source>
  <SynchronizeSecurity>CopyAll</SynchronizeSecurity>
  <ApplyCompression>true</ApplyCompression>
</Synchronize>', 
		@server=N'SSAS02\SSASTABULAR', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Sync MDXReport]    Script Date: 7/29/2022 12:35:30 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Sync MDXReport', 
		@step_id=12, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'ANALYSISCOMMAND', 
		@command=N'
<Synchronize xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns="http://schemas.microsoft.com/analysisservices/2003/engine">
  <Source>
    <ConnectionString>Provider=MSOLAP.8;Data Source=SSAS03;Integrated Security=SSPI;Initial Catalog=MDXReport</ConnectionString>
    <Object>
      <DatabaseID>MDXReport</DatabaseID>
    </Object>
  </Source>
  <SynchronizeSecurity>CopyAll</SynchronizeSecurity>
  <ApplyCompression>true</ApplyCompression>
</Synchronize>', 
		@server=N'SSAS02', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Daily sync', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20210712, 
		@active_end_date=99991231, 
		@active_start_time=220000, 
		@active_end_time=235959, 
		@schedule_uid=N'c44043fd-6651-438a-b3d3-265f84e9a5a8'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO


