/*
-----------------------------------------------------------------------
Data de Criação: 19/07/2022
Nome do Objeto: ti_Suporte_Registro_Backup
Autor: Ícaro

Alterações:
	[Ícaro - 04/09/2022] => Procedimento movido para um BD próprio
----------------------------------------------------------------------
*/
Use [REGISTRO_RESTORE_BD]
Go

If Exists (Select 1 From Sysobjects Where Id = Object_Id('Dbo.[ti_Suporte_Registro_Backup]'))
     Drop Trigger Dbo.[ti_Suporte_Registro_Backup]
Go

Create Trigger Dbo.[ti_Suporte_Registro_Backup] On [Suporte_Registro_Backup] After Insert As
Begin
     Set Nocount On;
	 
     If Trigger_Nestlevel(Object_Id('ti_Suporte_Registro_Backup')) > 1
          Return;
          
     Declare @Sql_Statement_Bd Nvarchar(Max)
			,@Sql_Statement_Desktop Nvarchar(Max)
			,@Nome_Bd Varchar(50)
			,@Sigla_Cliente Varchar(15)

	Set @Nome_Bd = (Select Nome_Banco From Inserted)
	Set @Nome_Bd = Quotename(@Nome_Bd)
	Set @Sigla_Cliente = (Select Cliente From Inserted)



	Set @Sql_Statement_Desktop = N' Update Suporte_Registro_Backup
									Set Versao_Desktop = (Select Max(Versao_Componente_Desktop_Atual)
														  From '+@Nome_Bd+'..Fw_Componentes_Desktop)
									From Suporte_Registro_Backup
									Where Cliente = '''+@Sigla_Cliente+''''					    

	 Set @Sql_Statement_Bd = N' Update Suporte_Registro_Backup
									Set Versao_Bd = (Select Max(Versao_Componente_Bd_Atual)
														  From '+@Nome_Bd+'..Fw_Componentes_Bd)
									From Suporte_Registro_Backup
									Where Cliente = '''+@Sigla_Cliente+''''

	 Exec Sp_Executesql @Sql_Statement_Desktop
	 Exec Sp_Executesql @Sql_Statement_Bd
          
     Set Nocount Off;
End
Go
