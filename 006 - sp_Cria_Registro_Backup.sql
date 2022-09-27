/*
-----------------------------------------------------------------------
Data de Criação: 19/07/2022
Nome do Objeto: sp_Cria_Registro_Backup
Autor: Ícaro

Alterações:
	[Ícaro - 04/09/2022] => Alterado a forma como a data da midia do backup é adquirida. Agora ao invés de fazer a inserção manualmente,
							o procedimento a adquire atraves da procedure "sp_RESTORE_HEADERONLY".

	[Ícaro - 04/09/2022] => Procedimento movido para um BD próprio

	[Ícaro - 27/09/2022] => Alterado o tipo da tabela criada para uma tabela temporaria, devido à conflitos caso mais de uma pessoa executasse o procedimento ao mesmo tempo.
						 => Removido a variável que guardava o statment de geração da tabela. A tabela passou a ser criada internamente na procedure.

----------------------------------------------------------------------
*/

Use [REGISTRO_RESTORE_BD]
Go

If Exists (Select 1 From Sysobjects Where Id = Object_Id('Dbo.[sp_Cria_Registro_Backup]'))
     Drop Procedure Dbo.sp_Cria_Registro_Backup
Go

Create Procedure Dbo.sp_Cria_Registro_Backup(
	@Tipo_Banco Char,
	@Sigla_Cliente Varchar(10),
	@diretorio_arq_bak nvarchar(360),
	@Observacoes Varchar(500)
)
As
	Begin

		Declare
			@Dt_Restauracao Datetime,
			@Tp_Bd Varchar(10),
			@Sql Nvarchar(500),
			@Instancia Nvarchar(50),
			@Versao_Desktop Varchar(12),
			@Versao_Bd Varchar(12),
			@Bd_Cliente Varchar(50),
			@DATA_MIDIA DATETIME

		Set @Dt_Restauracao = (Select Getdate())
		Set @Tp_Bd = (Select Case Upper(@Tipo_Banco) 
								When 'D' Then 'Dados' 
								When 'L' Then 'Log' 
								When 'B' Then 'Binários'
							 End
					 )
		
		Set @Sigla_Cliente = Upper(@Sigla_Cliente)
		Set @Instancia = Convert(Nvarchar(50), Serverproperty('Servername'))
		Set @Bd_Cliente = (select NOME_BANCO from PARAMETROS_RESTORE where CLIENTE = @Sigla_Cliente)
		Set @Bd_Cliente = Upper(@Bd_Cliente)

		--CRIANDO A TABELA PARA OS DADOS DO RESTORE HEADERONLY
		CREATE TABLE #tab_RESTORE_HEADERONLY(
								BackupName	nvarchar(100),
								BackupDescription nvarchar(100),	
								BackupType nvarchar(100),	
								ExpirationDate nvarchar(100),	
								Compressed nvarchar(100),	
								Position nvarchar(100),	
								DeviceType nvarchar(100),	
								UserName nvarchar(100),	
								ServerName nvarchar(100),	
								DatabaseName nvarchar(100),	
								DatabaseVersion nvarchar(100),	
								DatabaseCreationDate nvarchar(100),	
								BackupSize nvarchar(100),	
								FirstLSN nvarchar(100),	
								LastLSN nvarchar(100),	
								CheckpointLSN nvarchar(100),	
								DatabaseBackupLSN nvarchar(100),	
								BackupStartDate nvarchar(100),	
								BackupFinishDate DATETIME,	
								SortOrder nvarchar(100),	
								CodePage nvarchar(100),	
								UnicodeLocaleId nvarchar(100),	
								UnicodeComparisonStyle nvarchar(100),	
								CompatibilityLevel nvarchar(100),	
								SoftwareVendorId nvarchar(100),	
								SoftwareVersionMajor nvarchar(100),	
								SoftwareVersionMinor nvarchar(100),	
								SoftwareVersionBuild nvarchar(100),	
								MachineName nvarchar(100),	
								Flags nvarchar(100),	
								BindingID nvarchar(100),	
								RecoveryForkID nvarchar(100),	
								Collation nvarchar(100),	
								FamilyGUID nvarchar(100),	
								HasBulkLoggedData nvarchar(100),	
								IsSnapshot nvarchar(100),	
								IsReadOnly nvarchar(100),	
								IsSingleUser nvarchar(100),	
								HasBackupChecksums nvarchar(100),	
								IsDamaged nvarchar(100),	
								BeginsLogChain nvarchar(100),	
								HasIncompleteMetaData nvarchar(100),	
								IsForceOffline nvarchar(100),	
								IsCopyOnly nvarchar(100),	
								FirstRecoveryForkID nvarchar(100),	
								ForkPointLSN nvarchar(100),	
								RecoveryModel nvarchar(100),	
								DifferentialBaseLSN	nvarchar(100),
								DifferentialBaseGUID nvarchar(100),	
								BackupTypeDescription nvarchar(100),	
								BackupSetGUID nvarchar(100),	
								CompressedBackupSize nvarchar(100),	
								Containment nvarchar(100),	
								KeyAlgorithm nvarchar(100),	
								EncryptorThumbprint nvarchar(100),	
								EncryptorType nvarchar(100),
								)

		BEGIN
			INSERT #tab_RESTORE_HEADERONLY
			EXEC [REGISTRO_RESTORE_BD]..SP_PROC_RESTORE_HEADERONLY  @DIRETORIO_ARQ_BAK
		END

		SET @DATA_MIDIA = ( SELECT BackupFinishDate 
							FROM #tab_RESTORE_HEADERONLY 
							WHERE Position = 1
						  )

		--se ainda nao houver nenhum registro do cliente, cria um novo
		If Not Exists(Select 1 From Suporte_Registro_Backup Where Cliente = @Sigla_Cliente)
			Begin
				Insert [Dbo].[Suporte_Registro_Backup]
					 ([Cliente]
					, [Data_Restauracao]
					, [DATA_MIDIA_BACKUP]
					, [Tipo_Banco]
					, [Instancia_Atual]
					, [Nome_Banco]
					, [Observacoes]
					, [Versao_Desktop]
					, [Versao_Bd])

				Values(@Sigla_Cliente
					, @Dt_Restauracao
					, @DATA_MIDIA
					, @Tp_Bd
					, @Instancia
					, @Bd_Cliente
					, @Observacoes
					, Null
					, Null)
			End

		--cria um novo registro para o mesmo cliente caso já tenha algum banco de tipo diferente
		If Exists(Select 1 From Suporte_Registro_Backup Where Cliente = @Sigla_Cliente and Tipo_Banco <> @Tp_Bd)
			Begin
				Insert[Dbo].[Suporte_Registro_Backup]
					 ([Cliente]
					, [Data_Restauracao]
					, [DATA_MIDIA_BACKUP]
					, [Tipo_Banco]
					, [Instancia_Atual]
					, [Nome_Banco]
					, [Observacoes]
					, [Versao_Desktop]
					, [Versao_Bd])

			    Values(@Sigla_Cliente
					, @Dt_Restauracao
					, @DATA_MIDIA
					, @Tp_Bd
					, @Instancia
					, @Bd_Cliente
					, @Observacoes
					, Null
					, Null)
			End

		--atualiza as informações caso já haja um registro do mesmo cliente e do mesmo tipo de banco
		If Exists(Select 1 From Suporte_Registro_Backup Where Cliente = @Sigla_Cliente and Tipo_Banco = @Tp_Bd)
			Begin
				Update Suporte_Registro_Backup
				Set [Cliente] = @Sigla_Cliente
				, [Data_Restauracao] = @Dt_Restauracao
				, [DATA_MIDIA_BACKUP] = @DATA_MIDIA
				, [Tipo_Banco] = @Tp_Bd
				, [Instancia_Atual] = @Instancia
				, [Nome_Banco] = @Bd_Cliente
				, [Observacoes] = @Observacoes
				, [Versao_Desktop] = Null
				, [Versao_Bd] = Null
				From [REGISTRO_RESTORE_BD].Dbo.Suporte_Registro_Backup Srb
				Where Srb.Cliente = @Sigla_Cliente
					And Srb.Tipo_Banco = @Tp_Bd
			End

		BEGIN
			DROP TABLE #tab_RESTORE_HEADERONLY
		END
	End
Go