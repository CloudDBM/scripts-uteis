/****** Script do comando SelectTopNRows de SSMS  ******/
SELECT [cod_servidor] AS [cod_servidor]
	  ,REPLACE(REPLACE(REPLACE(REPLACE(CAST([TextData] AS VARCHAR(300)), CHAR(9), ''), CHAR(10), ''), CHAR(13), ''),';','') AS [TextData]
      ,[DatabaseID] AS [DatabaseID]
      ,[NTUserName] AS [NTUserName]
      ,[HostName] AS [HostName]
      ,[ApplicationName] AS [ApplicationName]
      ,[LoginName] AS [LoginName]
      ,[Duration] AS [Duration]
      ,[StartTime] AS [StartTime]
  FROM [DBManager].[dbo].[trace_daily]
    WHERE [StartTime] >= '2022-01-17 08:00:00.000'
  AND [Duration] >= 5