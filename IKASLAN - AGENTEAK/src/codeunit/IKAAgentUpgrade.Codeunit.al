codeunit 99061 "IKA Agent Upgrade"
{
    // Al actualizar desde la extensión de ventas (1.x) los campos nuevos de albaranes de un registro
    // de configuración ya existente quedan a 0 / falso (InitValue solo se aplica a registros nuevos).
    // Aquí se les da su valor por defecto una sola vez.
    Subtype = Upgrade;

    trigger OnUpgradePerCompany()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(DeliveryNoteDefaultsTag()) then
            exit;
        SetDeliveryNoteDefaults();
        UpgradeTag.SetUpgradeTag(DeliveryNoteDefaultsTag());
    end;

    local procedure SetDeliveryNoteDefaults()
    var
        Setup: Record "IKA Sales Agent Setup";
    begin
        if not Setup.Get() then
            exit;
        Setup."DN Mail Enabled" := true;
        Setup."DN Only Unread" := true;
        Setup."DN Mark as Read" := true;
        Setup."DN Max Documents per Run" := 20;
        Setup."DN Max File Size (KB)" := 20480;
        Setup."Price Tolerance %" := 0.5;
        Setup."Search Other Open Orders" := true;
        Setup."DN Allow Description Match" := true;
        Setup."DN Min. Confidence" := 0.9;
        Setup."Reset Qty. to Receive" := true;
        Setup."DN Job Interval (min)" := 15;
        Setup.Modify();
    end;

    local procedure DeliveryNoteDefaultsTag(): Code[250]
    begin
        exit('IKA-AGENTS-DN-SETUP-DEFAULTS-20261007');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", 'OnGetPerCompanyUpgradeTags', '', false, false)]
    local procedure RegisterPerCompanyTags(var PerCompanyUpgradeTags: List of [Code[250]])
    begin
        PerCompanyUpgradeTags.Add(DeliveryNoteDefaultsTag());
    end;
}
