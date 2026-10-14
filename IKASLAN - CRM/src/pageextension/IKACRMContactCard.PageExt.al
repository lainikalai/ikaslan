pageextension 99411 "IKA CRM Contact Card" extends "Contact Card"
{
    layout
    {
        addfirst(factboxes)
        {
            part("IKA CRM FactBox"; "IKA CRM FactBox")
            {
                ApplicationArea = All;
                Visible = CrmEnabled;
            }
        }
    }

    var
        CrmEnabled: Boolean;

    trigger OnOpenPage()
    var
        CrmSetup: Record "IKA CRM Setup";
    begin
        if CrmSetup.Get() then
            CrmEnabled := CrmSetup.Enabled;
    end;

    trigger OnAfterGetCurrRecord()
    begin
        if not CrmEnabled then
            exit;
        CurrPage."IKA CRM FactBox".Page.SetSource(Database::Contact, Rec."No.");
        CurrPage."IKA CRM FactBox".Page.Update(false);
    end;
}
