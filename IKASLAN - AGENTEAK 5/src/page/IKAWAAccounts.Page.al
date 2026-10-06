page 99306 "IKA WA Accounts"
{
    Caption = 'Cuentas de WhatsApp Business';
    PageType = List;
    SourceTable = "IKA WA Account";
    UsageCategory = Administration;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Code"; Rec.Code)
                {
                    ApplicationArea = All;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
                field("Display Phone Number"; Rec."Display Phone Number")
                {
                    ApplicationArea = All;
                }
                field("Phone Number ID"; Rec."Phone Number ID")
                {
                    ApplicationArea = All;
                }
                field("Business Account ID"; Rec."Business Account ID")
                {
                    ApplicationArea = All;
                }
                field(Enabled; Rec.Enabled)
                {
                    ApplicationArea = All;
                }
                field("Restricted to User ID"; Rec."Restricted to User ID")
                {
                    ApplicationArea = All;
                }
                field(TokenStatus; TokenStatus)
                {
                    ApplicationArea = All;
                    Caption = 'Token de acceso';
                    Editable = false;
                    ToolTip = 'Se guarda cifrado en Isolated Storage. Use "Establecer token".';
                }
                field("Last Template Sync"; Rec."Last Template Sync")
                {
                    ApplicationArea = All;
                }
                field("No. of Conversations"; Rec."No. of Conversations")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SetToken)
            {
                ApplicationArea = All;
                Caption = 'Establecer token';
                Image = EncryptionKeys;
                ToolTip = 'Token permanente de un usuario del sistema de Meta Business Manager con permisos whatsapp_business_messaging y whatsapp_business_management.';

                trigger OnAction()
                var
                    SecretInput: Page "IKA WA Secret Input";
                begin
                    CurrPage.SaveRecord();
                    if SecretInput.RunModal() = Action::OK then
                        Rec.SetAccessToken(SecretInput.GetSecret());
                    CurrPage.Update(false);
                end;
            }
            action(TestConnection)
            {
                ApplicationArea = All;
                Caption = 'Probar conexión';
                Image = TestDatabase;
                ToolTip = 'Comprueba el token y el Phone Number ID.';

                trigger OnAction()
                var
                    CloudApi: Codeunit "IKA WA Cloud API";
                begin
                    CurrPage.SaveRecord();
                    Message('%1', CloudApi.TestAccount(Rec));
                end;
            }
            action(SyncTemplates)
            {
                ApplicationArea = All;
                Caption = 'Sincronizar plantillas';
                Image = Refresh;
                ToolTip = 'Trae de Meta las plantillas de la cuenta y su estado de aprobación.';

                trigger OnAction()
                var
                    CloudApi: Codeunit "IKA WA Cloud API";
                    SyncedMsg: Label '%1 plantilla(s) sincronizada(s).', Comment = '%1 = count';
                begin
                    CurrPage.SaveRecord();
                    Message(SyncedMsg, CloudApi.SyncTemplates(Rec));
                end;
            }
        }
        area(Navigation)
        {
            action(Templates)
            {
                ApplicationArea = All;
                Caption = 'Plantillas';
                Image = Template;
                RunObject = page "IKA WA Templates";
                RunPageLink = "Account Code" = field(Code);
                ToolTip = 'Plantillas de esta cuenta.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Proceso';

                actionref(SetToken_Promoted; SetToken) { }
                actionref(TestConnection_Promoted; TestConnection) { }
                actionref(SyncTemplates_Promoted; SyncTemplates) { }
                actionref(Templates_Promoted; Templates) { }
            }
        }
    }

    var
        TokenStatus: Text;

    trigger OnAfterGetRecord()
    begin
        if Rec.HasAccessToken() then
            TokenStatus := 'Configurado ✔'
        else
            TokenStatus := 'No configurado';
    end;

    trigger OnOpenPage()
    begin
        Rec.FilterGroup(2);
        Rec.SetFilter("Restricted to User ID", '%1|%2', '', UpperCase(UserId()));
        Rec.FilterGroup(0);
    end;
}
