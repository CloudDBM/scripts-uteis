/*
Procedure que realiza o backup de todos os bancos com opção de se colocar alguns como exceção.
Caso rode a partir de um job que falhe em algum momento, quando for executar novamente, 
vai continuar fazendo os backups a partir dos que ainda não foram executados.
*/
USE [master]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER procedure [dbo].[spu_backup_full]                       
 @database nvarchar(500) = null                                        
as                      
                        
declare @device  nvarchar(2000)                                
declare @pathbackup nvarchar(2000)                                
declare @cmdcrtdev nvarchar(2000)                                
declare @cmddrpdev nvarchar(2000)                                
declare @cmdbkp  nvarchar(2000)                                            
declare @table table (database_name varchar(500))                   
declare @excecao table (database_name varchar(500))                  
                                
--determina path do diretório para backup                                
set @pathbackup = 'D:\BackupFiles\'      --Caso esta linha for alterada deverá alterar a abaixo seguindo o padrão                                
                    
IF OBJECT_ID(N'tempdb..##INFORMACOES_BACKUP') IS NOT NULL
	DROP TABLE ##INFORMACOES_BACKUP

CREATE TABLE ##INFORMACOES_BACKUP (
	servidor VARCHAR(256),
	banco VARCHAR(256),
	backup_date DATETIME,
	backup_horas INT
)
	
INSERT INTO ##INFORMACOES_BACKUP
SELECT 
   CONVERT(CHAR(100), SERVERPROPERTY('Servername')) AS Server, 
   msdb.dbo.backupset.database_name, 
   MAX(msdb.dbo.backupset.backup_finish_date) AS last_db_backup_date, 
   DATEDIFF(hh, MAX(msdb.dbo.backupset.backup_finish_date), GETDATE()) AS [Backup Age (Hours)] 
FROM 
   msdb.dbo.backupset 
WHERE 
   msdb.dbo.backupset.type = 'D'  
   AND msdb.dbo.backupset.backup_finish_date IS NOT NULL 
GROUP BY 
   msdb.dbo.backupset.database_name 
HAVING 
   (MAX(msdb.dbo.backupset.backup_finish_date) > DATEADD(hh, - 48, GETDATE()))  

UNION  
--Databases without any backup history 
SELECT      
   CONVERT(CHAR(100), SERVERPROPERTY('Servername')) AS Server,  
   master.sys.sysdatabases.NAME AS database_name,  
   NULL AS [Last Data Backup Date],  
   9999 AS [Backup Age (Hours)]  
FROM 
   master.sys.sysdatabases 
   LEFT JOIN msdb.dbo.backupset ON master.sys.sysdatabases.name = msdb.dbo.backupset.database_name 
WHERE 
   msdb.dbo.backupset.database_name IS NULL 
   AND master.sys.sysdatabases.name <> 'tempdb' 
   AND msdb.dbo.backupset.backup_finish_date IS NOT NULL 
ORDER BY  
   msdb.dbo.backupset.database_name 

	
-- determina os bancos de excecao                  
insert into @excecao                  
select name from sysdatabases where name in ('tempdb', 'AdventureWorks2019')  
or (databasepropertyex(name, 'STATUS') =  'RESTORING') 
or (DATABASEPROPERTYEX(name, 'IsInStandBy') = 1)                
UNION	
SELECT banco from ##INFORMACOES_BACKUP
                 
                  
                  
-- verifica se o parametro banco foi informado, se não executa para todos os bancos                      
if @database is not null                      
 begin                       
  insert into @table                      
  select name from sysdatabases where name = @database                      
 end                      
else                      
 begin                       
  insert into @table                      
  select name from sysdatabases where name not in (select database_name from @excecao)                  
 end                      
                    
------------                                
declare devices cursor for                                
select name from sysdevices                              
open devices                                
fetch next from devices into @device                                
while @@fetch_status = 0                                
 begin                                  
  --apaga device não necessários                                
  select @cmddrpdev = 'sp_dropdevice '''+name+''', delfile;'                                
  from sysdevices where name not like 'BkpLG%'                                
  and name not in (select 'Bkp'+name from sysdatabases)                                 
  and name not in (select 'Bkp'+name+'Diff' from sysdatabases)
  and name not in ('master','mastlog','modeldev','modellog','tempdev','templog')                               
  and name = @device                                  
  print @cmddrpdev                      
  exec(@cmddrpdev)                                
  fetch next from devices into @device                                
 end                                
close devices                                
deallocate devices                                   
-----------------------                    
                    
declare databases cursor for                                    
select database_name from @table                           
open databases                                        
fetch next from databases                                
into @database                                
while @@fetch_status = 0                                
 begin                                
  --cria device de backup full para database se não existe                                
  select @cmdcrtdev = 'if not exists (select 1 from sysdevices where name = ''Bkp'+name+''')'+char(13)+'exec sp_addumpdevice ''disk'', ''Bkp'+name+''', '''+@pathbackup+'Bkp'+name+'.bak'''+';',                                
  @cmdbkp  = 'backup database ['+name+'] to [Bkp'+name+'] with format,stats=1;'                              


  from sysdatabases where name = @database
                 
  exec(@cmdcrtdev)                                
  print 'Inicio do Backup do Database: '+@database+ ' - ' +cast(getdate() as varchar)                       
  print @cmdbkp                            
  exec(@cmdbkp)                        
  print 'Fim do Backup do Database: '+@database+ ' - ' +cast(getdate() as varchar)                                
  print ''                                
  fetch next from databases into @database                                
 end                                
close databases                                
deallocate databases 
