page 50020 "DECA Card"
{
    Caption = 'DeCA';
    PageType = Document;
    SourceTable = "DECA Header";
    UsageCategory = None;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Número del DeCA. Se asigna al crear el registro.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    StyleExpr = StatusStyle;
                    ToolTip = 'Borrador, Emitido o Sustituido.';
                }
                field("Transport Date"; Rec."Transport Date")
                {
                    ApplicationArea = All;
                    Editable = IsDraft;
                    ToolTip = 'Fecha de realización del transporte del envío.';
                }
                field("Service End Date"; Rec."Service End Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Fecha en la que termina el servicio. La URL sigue activa al menos 7 días naturales después.';
                }
                field("Source Type"; Rec."Source Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Documento del que procede.';
                }
                field("Source No."; Rec."Source No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Número del documento de origen.';
                }
            }
            group(Shipper)
            {
                Caption = 'Cargador contractual';
                Editable = IsDraft;

                field("Shipper Customer No."; Rec."Shipper Customer No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Cliente que contrata el transporte. Rellena los datos del cargador.';
                }
                field("Shipper Name"; Rec."Shipper Name") { ApplicationArea = All; ShowMandatory = true; ToolTip = 'Nombre o denominación social del cargador contractual.'; }
                field("Shipper VAT Registration No."; Rec."Shipper VAT Registration No.") { ApplicationArea = All; ShowMandatory = true; ToolTip = 'NIF del cargador contractual.'; }
                field("Shipper Address"; Rec."Shipper Address") { ApplicationArea = All; ShowMandatory = true; ToolTip = 'Domicilio del cargador contractual.'; }
                field("Shipper Address 2"; Rec."Shipper Address 2") { ApplicationArea = All; ToolTip = 'Domicilio del cargador contractual (continuación).'; }
                field("Shipper Post Code"; Rec."Shipper Post Code") { ApplicationArea = All; ToolTip = 'Código postal.'; }
                field("Shipper City"; Rec."Shipper City") { ApplicationArea = All; ShowMandatory = true; ToolTip = 'Población.'; }
                field("Shipper County"; Rec."Shipper County") { ApplicationArea = All; ToolTip = 'Provincia.'; }
            }
            group(Carrier)
            {
                Caption = 'Transportista efectivo';
                Editable = IsDraft;

                field("Shipping Agent Code"; Rec."Shipping Agent Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Transportista de Business Central. Rellena nombre, NIF y email.';
                }
                field("Carrier Name"; Rec."Carrier Name") { ApplicationArea = All; ShowMandatory = true; ToolTip = 'Nombre o denominación social del titular de la autorización que realiza materialmente el transporte.'; }
                field("Carrier VAT Registration No."; Rec."Carrier VAT Registration No.") { ApplicationArea = All; ShowMandatory = true; ToolTip = 'NIF del transportista efectivo.'; }
            }
            group(Transport)
            {
                Caption = 'Vehículo y conductor';
                Editable = IsDraft;

                field("Vehicle Plate No."; Rec."Vehicle Plate No.") { ApplicationArea = All; ShowMandatory = true; ToolTip = 'Matrícula del vehículo. En conjuntos articulados, la del tractor.'; }
                field("Trailer Plate No."; Rec."Trailer Plate No.") { ApplicationArea = All; ToolTip = 'Matrícula del semirremolque o remolque.'; }
                field("Driver Name"; Rec."Driver Name") { ApplicationArea = All; ToolTip = 'Nombre del conductor (informativo).'; }
                field("Special Circulation Permit"; Rec."Special Circulation Permit") { ApplicationArea = All; ToolTip = 'Identificación de la autorización especial de circulación, cuando sea necesaria.'; }
                field(Remarks; Rec.Remarks) { ApplicationArea = All; MultiLine = true; ToolTip = 'Observaciones, reservas u otras indicaciones.'; }
            }
            part(Lines; "DECA Subform")
            {
                ApplicationArea = All;
                Caption = 'Envíos';
                SubPageLink = "Document No." = field("No.");
                Editable = IsDraft;
                UpdatePropagation = Both;
            }
            group(Issuing)
            {
                Caption = 'Emisión';

                field("Driver E-Mail"; Rec."Driver E-Mail") { ApplicationArea = All; ToolTip = 'Dirección a la que se envía el DeCA (conductor o tráfico del transportista).'; }
                field("Document URL"; Rec."Document URL") { ApplicationArea = All; ToolTip = 'URL única de descarga directa del PDF. Es la que contiene el código QR.'; }
                field("Issued At"; Rec."Issued At") { ApplicationArea = All; ToolTip = 'Fecha y hora de creación del fichero electrónico.'; }
                field("Issued By"; Rec."Issued By") { ApplicationArea = All; ToolTip = 'Usuario que emitió el DeCA.'; }
                field("Version No."; Rec."Version No.") { ApplicationArea = All; ToolTip = 'Versión del documento.'; }
                field("Replaces DeCA No."; Rec."Replaces DeCA No.") { ApplicationArea = All; ToolTip = 'DeCA al que sustituye este.'; }
                field("Modification Reason"; Rec."Modification Reason")
                {
                    ApplicationArea = All;
                    Editable = IsDraft;
                    MultiLine = true;
                    ToolTip = 'Motivo del cambio. Obligatorio cuando el DeCA sustituye a otro.';
                }
                field("Replaced by DeCA No."; Rec."Replaced by DeCA No.") { ApplicationArea = All; ToolTip = 'DeCA que sustituye a este.'; }
                field("URL Disabled"; Rec."URL Disabled") { ApplicationArea = All; ToolTip = 'Indica si la descarga por URL ya está desactivada.'; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Issue)
            {
                ApplicationArea = All;
                Caption = 'Emitir';
                Image = Approve;
                Enabled = IsDraft;
                ToolTip = 'Genera el PDF con el código QR, lo publica en el repositorio y registra la fecha y hora de creación.';

                trigger OnAction()
                var
                    DECAManagement: Codeunit "DECA Management";
                begin
                    CurrPage.SaveRecord();
                    DECAManagement.Issue(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(SendByEmail)
            {
                ApplicationArea = All;
                Caption = 'Enviar por email';
                Image = Email;
                Enabled = not IsDraft;
                ToolTip = 'Envía el PDF y la URL a la dirección indicada.';

                trigger OnAction()
                var
                    DECAManagement: Codeunit "DECA Management";
                begin
                    CurrPage.SaveRecord();
                    DECAManagement.SendByEmail(Rec);
                end;
            }
            action(DownloadPdf)
            {
                ApplicationArea = All;
                Caption = 'Descargar PDF';
                Image = Export;
                Enabled = not IsDraft;
                ToolTip = 'Descarga la copia del PDF conservada en Business Central.';

                trigger OnAction()
                var
                    DECAManagement: Codeunit "DECA Management";
                begin
                    DECAManagement.DownloadPdf(Rec);
                end;
            }
            action(OpenUrl)
            {
                ApplicationArea = All;
                Caption = 'Probar URL';
                Image = Navigate;
                Enabled = not IsDraft;
                ToolTip = 'Abre la URL del código QR para comprobar que descarga el PDF directamente.';

                trigger OnAction()
                begin
                    Rec.TestField("Document URL");
                    Hyperlink(Rec."Document URL");
                end;
            }
            action(Replace)
            {
                ApplicationArea = All;
                Caption = 'Modificar (nueva versión)';
                Image = Copy;
                Enabled = CanReplace;
                ToolTip = 'Crea un nuevo DeCA con todos los datos para corregirlos. Tendrá nueva URL y nuevo QR; el original se conserva.';

                trigger OnAction()
                var
                    NewHeader: Record "DECA Header";
                    DECAManagement: Codeunit "DECA Management";
                begin
                    NewHeader.Get(DECAManagement.CreateReplacement(Rec));
                    Page.Run(Page::"DECA Card", NewHeader);
                end;
            }
            action(Preview)
            {
                ApplicationArea = All;
                Caption = 'Vista previa';
                Image = Print;
                ToolTip = 'Muestra el documento. En borrador no lleva QR y no es válido.';

                trigger OnAction()
                var
                    DECAHeader: Record "DECA Header";
                begin
                    CurrPage.SaveRecord();
                    DECAHeader.SetRange("No.", Rec."No.");
                    Report.Run(Report::"DECA Document", true, false, DECAHeader);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Proceso';

                actionref(Issue_Promoted; Issue) { }
                actionref(SendByEmail_Promoted; SendByEmail) { }
                actionref(DownloadPdf_Promoted; DownloadPdf) { }
                actionref(Replace_Promoted; Replace) { }
                actionref(Preview_Promoted; Preview) { }
            }
        }
    }

    var
        IsDraft: Boolean;
        CanReplace: Boolean;
        StatusStyle: Text;

    trigger OnAfterGetCurrRecord()
    begin
        SetControls();
    end;

    trigger OnAfterGetRecord()
    begin
        SetControls();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        SetControls();
    end;

    local procedure SetControls()
    begin
        IsDraft := Rec.Status = Rec.Status::Draft;
        CanReplace := Rec.Status = Rec.Status::Issued;
        case Rec.Status of
            Rec.Status::Issued:
                StatusStyle := 'Favorable';
            Rec.Status::Replaced:
                StatusStyle := 'Subordinate';
            else
                StatusStyle := 'Standard';
        end;
    end;
}
