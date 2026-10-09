pageextension 99406 "IKA CRM Vendor Card" extends "Vendor Card"
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
        CurrPage."IKA CRM FactBox".Page.SetSource(Database::Vendor, Rec."No.");
        CurrPage."IKA CRM FactBox".Page.Update(false);
    end;
}
