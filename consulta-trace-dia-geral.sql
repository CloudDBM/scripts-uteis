/****** Script do comando SelectTopNRows de SSMS  ******/
SELECT CONCAT([cod_servidor],'') AS [cod_servidor]
      ,CONCAT(SUBSTRING(CAST(REPLACE(REPLACE(CAST([TextData] as NVarchar(MAX)),CHAR(13) + Char(10) ,' '),Char(9),' ')  AS NText),1,2000),'') AS [TextData]
      ,CONCAT([DatabaseID],'') AS [DatabaseID]
      ,CONCAT([NTUserName],'') AS [NTUserName]
      ,CONCAT([HostName],'') AS [HostName]
      ,CONCAT([ApplicationName],'') AS [ApplicationName]
      ,CONCAT([LoginName],'') AS [LoginName]
      ,CONCAT([Duration],'') AS [Duration]
      ,CONCAT([StartTime],'') AS [StartTime]
  FROM [DBManager].[dbo].[trace_daily]
    WHERE [StartTime] > '2022-12-15 08:00:00.000'
  AND [Duration] >= 30
  AND [TextData] NOT LIKE '%--%'