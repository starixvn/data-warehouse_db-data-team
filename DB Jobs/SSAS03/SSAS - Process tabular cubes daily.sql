USE [msdb]
GO

/****** Object:  Job [SSAS - Process tabular cubes daily]    Script Date: 7/13/2022 12:07:41 AM ******/
EXEC msdb.dbo.sp_delete_job @job_id=N'3480bccc-6657-42c2-9156-2fb15813a53d', @delete_unused_schedule=1
GO

/****** Object:  Job [SSAS - Process tabular cubes daily]    Script Date: 7/13/2022 12:07:41 AM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 7/13/2022 12:07:41 AM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'SSAS - Process tabular cubes daily', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=3, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'vnDan', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Check data ready for top 1 cube to process]    Script Date: 7/13/2022 12:07:41 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Check data ready for top 1 cube to process', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=200, 
		@retry_interval=1, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'exec [DBSTAGING].bodb_OLAP.dbo.[ETL_Tabular_PartialProcessCheckReady]

/*
IF (
	NOT EXISTS 
	(	
	select TOP 1 *
	from 
		OPENQUERY (DBSTAGING,
	''Select [Cube], FirstDate, LastDate
	From bodb_dwrs.dbo.VIEW_DW_STATUS
	Where [Cube]= ''''DW''''
	and LastDate = cast(getdate() -1 as date)
	''
		)
	)
)
BEGIN
    RAISERROR(''Source data is not ready.'',16,1)
END
*/
', 
		@database_name=N'master', 
		@flags=4
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Process tabular cube]    Script Date: 7/13/2022 12:07:41 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Process tabular cube', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'SSIS', 
		@command=N'/FILE "\"G:\ETL\SSASTabular_DailyCubeProcessing\TabularProcessing.dtsx\"" /DECRYPT 1234aa /CHECKPOINTING OFF /REPORTING E', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Check and process next cube]    Script Date: 7/13/2022 12:07:41 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Check and process next cube', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=4, 
		@on_fail_step_id=1, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'IF EXISTS(
	SELECT top 1 *
	FROM [DBSTAGING].[bodb_OLAP].[dbo].[TabularDatabase]
	where IsActive=1
	and StartProcessedDateTime < cast(getdate() as DATE) --not yet process today
	order by OrderProcessing
	)
BEGIN
    RAISERROR(''process next cube'',16,1)
END', 
		@database_name=N'master', 
		@flags=4
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'SSAS tabular daily', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20190506, 
		@active_end_date=99991231, 
		@active_start_time=13000, 
		@active_end_time=235959, 
		@schedule_uid=N'42f9502b-d18e-4a5f-b4da-f030e14f2531'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO


