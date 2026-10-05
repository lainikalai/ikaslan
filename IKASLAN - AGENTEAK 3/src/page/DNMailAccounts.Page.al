page 50290 "IKA DN Mail Accounts"
{
    Caption = 'Cuentas de Outlook 365';
    PageType = List;
    SourceTable = "IKA DN Mail Account";
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
                field(Address; Rec.Address)
                {
                    ApplicationArea = All;
                    ToolTip = 'Dirección de la cuenta de Outlook 365 (buzón personal o compartido).';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
                field("Account Type"; Rec."Account Type")
                {
                    ApplicationArea = All;
                }
                field(Enabled; Rec.Enabled)
                {
                    ApplicationArea = All;
                }
                field(Folder; Rec.Folder)
                {
                    ApplicationArea = All;
                }
                field("Restricted to User ID"; Rec."Restricted to User ID")
                {
                    ApplicationArea = All;
                }
                field("Use Own Credentials"; Rec."Use Own Credentials")
                {
                    ApplicationArea = All;
                }
                field("Tenant Id"; Rec."Tenant Id")
                {
                    ApplicationArea = All;
                    Editable = Rec."Use Own Credentials";
                    ToolTip = 'Solo para cuentas de otro tenant de Microsoft 365.';
                }
                field("Client Id"; Rec."Client Id")
                {
                    ApplicationArea = All;
                    Editable = Rec."Use Own Credentials";
                    ToolTip = 'Solo para cuentas de otro tenant de Microsoft 365.';
                }
                field(SecretStatus; SecretStatus)
                {
                    ApplicationArea = All;
                    Caption = 'Secreto propio';
                    Editable = false;
                    ToolTip = 'Use la acción "Establecer secreto propio".';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(AddMyAccount)
            {
                ApplicationArea = All;
                Caption = 'Añadir mi cuenta';
                Image = User;
                ToolTip = 'Crea su cuenta personal con el email de su usuario de Business Central.';

                trigger OnAction()
                var
                    Mailbox: Record "IKA DN Mail Account";
                begin
                    Mailbox.Get(Mailbox.AddCurrentUserAccount());
                    Rec := Mailbox;
                    CurrPage.Update(false);
                end;
            }
            action(SetOwnSecret)
            {
                ApplicationArea = All;
                Caption = 'Establecer secreto propio';
                Image = EncryptionKeys;
                Enabled = Rec."Use Own Credentials";
                ToolTip = 'Secreto de cliente del registro de aplicación del otro tenant.';

                trigger OnAction()
                var
                    SecretInput: Page "IKA DN Secret Input";
                begin
                    if SecretInput.RunModal() = Action::OK then
                        Rec.SetClientSecret(SecretInput.GetSecret());
                    CurrPage.Update(false);
                end;
            }
            action(TestConnection)
            {
                ApplicationArea = All;
                Caption = 'Probar conexión';
                Image = TestDatabase;
                ToolTip = 'Comprueba el acceso a la cuenta y a su carpeta.';

                trigger OnAction()
                var
                    GraphClient: Codeunit "IKA DN Graph Client";
                begin
                    CurrPage.SaveRecord();
                    Message('%1', GraphClient.TestAccount(Rec));
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Proceso';

                actionref(AddMyAccount_Promoted; AddMyAccount) { }
                actionref(TestConnection_Promoted; TestConnection) { }
                actionref(SetOwnSecret_Promoted; SetOwnSecret) { }
            }
        }
    }

    var
        SecretStatus: Text;

    trigger OnAfterGetRecord()
    begin
        SecretStatus := '';
        if Rec."Use Own Credentials" then
            if Rec.HasClientSecret() then
                SecretStatus := 'Configurado ✔'
            else
                SecretStatus := 'No configurado';
    end;

    trigger OnOpenPage()
    begin
        // Cada usuario ve las cuentas compartidas y las suyas
        Rec.FilterGroup(2);
        Rec.SetFilter("Restricted to User ID", '%1|%2', '', UpperCase(UserId()));
        Rec.FilterGroup(0);
    end;
}
