page 99431 "IKA CRM Contacts Part"
{
    Caption = 'Contactos';
    PageType = ListPart;
    SourceTable = "IKA CRM Contact Buffer";
    SourceTableView = sorting("Sorting No.");
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Full Name"; Rec."Full Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Nombre completo.';
                }
                field("Job Title"; Rec."Job Title")
                {
                    ApplicationArea = All;
                    ToolTip = 'Puesto.';
                }
                field("E-Mail"; Rec."E-Mail")
                {
                    ApplicationArea = All;
                    ToolTip = 'Correo electrónico.';
                }
                field(Phone; Rec.Phone)
                {
                    ApplicationArea = All;
                    ToolTip = 'Teléfono del trabajo.';
                }
                field("Mobile Phone"; Rec."Mobile Phone")
                {
                    ApplicationArea = All;
                    ToolTip = 'Teléfono móvil.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(OpenInCrm)
            {
                ApplicationArea = All;
                Caption = 'Abrir en el CRM';
                Image = Web;
                ToolTip = 'Abre el contacto en el CRM.';

                trigger OnAction()
                var
                    DataMgt: Codeunit "IKA CRM Data Mgt.";
                begin
                    DataMgt.OpenInCrm('contact', Rec."Contact Id");
                end;
            }
        }
    }

    procedure SetData(var TempContact: Record "IKA CRM Contact Buffer" temporary)
    begin
        Rec.Reset();
        Rec.DeleteAll();
        if TempContact.FindSet() then
            repeat
                Rec := TempContact;
                Rec.Insert();
            until TempContact.Next() = 0;
        if Rec.FindFirst() then;
    end;
}
