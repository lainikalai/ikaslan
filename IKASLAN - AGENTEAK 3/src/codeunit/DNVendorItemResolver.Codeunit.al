codeunit 50230 "IKA DN Vendor Item Resolver"
{
    // Identifica en BC el proveedor y los productos de un albarán extraído por Claude.
    // Lógica determinista: no interviene la IA.

    var
        MethodTemplateLbl: Label 'Plantilla (remitente/fichero)';
        MethodVatLbl: Label 'NIF';
        MethodOurAccountLbl: Label 'Nuestro nº cliente';
        MethodEmailLbl: Label 'Email';
        MethodDomainLbl: Label 'Dominio remitente';
        MethodNameLbl: Label 'Nombre';
        MethodVendorRefLbl: Label 'Referencia proveedor';
        MethodItemVendorLbl: Label 'Catálogo proveedor';
        MethodItemVendorNoLbl: Label 'Cód. proveedor en ficha producto';
        MethodItemNoLbl: Label 'Nº producto';
        MethodEanLbl: Label 'EAN';
        MethodOpenOrderLbl: Label 'Cód. proveedor en pedido abierto';
        MethodDescriptionOrderLbl: Label 'Descripción en pedido abierto';
        MethodDescriptionLbl: Label 'Descripción';
        VendorNotFoundLbl: Label 'No se ha identificado el proveedor.';
        VendorAmbiguousLbl: Label 'Hay varios proveedores posibles (%1).', Comment = '%1 = method';
        VendorBlockedLbl: Label 'El proveedor %1 está bloqueado.', Comment = '%1 = vendor';
        ItemAmbiguousLbl: Label 'Varios productos coinciden por %1.', Comment = '%1 = method';
        ItemNotFoundLbl: Label 'Producto no encontrado.';

    // ---------------- Proveedor ----------------

    procedure ResolveVendor(var DNDocument: Record "IKA DN Document")
    var
        Vendor: Record Vendor;
    begin
        if (DNDocument."Vendor Match Status" = DNDocument."Vendor Match Status"::Manual) and (DNDocument."Vendor No." <> '') then begin
            CheckVendorBlocked(DNDocument);
            exit;
        end;
        DNDocument."Vendor No." := '';
        DNDocument."Vendor Match Status" := DNDocument."Vendor Match Status"::"Not Found";
        DNDocument."Vendor Match Method" := '';

        if DNDocument."Template Vendor No." <> '' then
            if SetVendor(DNDocument, DNDocument."Template Vendor No.", MethodTemplateLbl) then
                exit;
        if TryVendorByVat(DNDocument) then
            exit;
        if DNDocument."Ext. Our Customer Code" <> '' then begin
            Vendor.SetRange("Our Account No.", CopyStr(DNDocument."Ext. Our Customer Code", 1, MaxStrLen(Vendor."Our Account No.")));
            if MatchSingleVendor(DNDocument, Vendor, MethodOurAccountLbl) then
                exit;
        end;
        if TryVendorByEmail(DNDocument, DNDocument."Ext. Vendor E-Mail") then
            exit;
        if TryVendorByEmail(DNDocument, DNDocument."Sender Address") then
            exit;
        if TryVendorByDomain(DNDocument) then
            exit;
        if TryVendorByName(DNDocument) then
            exit;

        if DNDocument."Vendor Match Status" = DNDocument."Vendor Match Status"::"Not Found" then
            DNDocument.AddReviewNote(VendorNotFoundLbl);
    end;

    local procedure TryVendorByVat(var DNDocument: Record "IKA DN Document"): Boolean
    var
        Vendor: Record Vendor;
        Vat: Text;
    begin
        Vat := UpperCase(DelChr(DNDocument."Ext. Vendor VAT No.", '=', ' .-/'));
        if StrLen(Vat) < 5 then
            exit(false);
        if CopyStr(Vat, 1, 2) = 'ES' then
            Vat := DelStr(Vat, 1, 2);
        Vendor.SetFilter("VAT Registration No.", '%1|%2', Vat, 'ES' + Vat);
        exit(MatchSingleVendor(DNDocument, Vendor, MethodVatLbl));
    end;

    local procedure TryVendorByEmail(var DNDocument: Record "IKA DN Document"; Email: Text): Boolean
    var
        Vendor: Record Vendor;
    begin
        Email := LowerCase(DelChr(Email, '<>', ' '));
        if (Email = '') or (StrPos(Email, '@') = 0) or (StrLen(Email) > MaxStrLen(Vendor."E-Mail")) then
            exit(false);
        Vendor.SetRange("E-Mail", Email);
        exit(MatchSingleVendor(DNDocument, Vendor, MethodEmailLbl));
    end;

    local procedure TryVendorByDomain(var DNDocument: Record "IKA DN Document"): Boolean
    var
        Vendor: Record Vendor;
        Domain: Text;
        FoundVendorNo: Code[20];
        MatchCount: Integer;
    begin
        if StrPos(DNDocument."Sender Address", '@') = 0 then
            exit(false);
        Domain := LowerCase(CopyStr(DNDocument."Sender Address", StrPos(DNDocument."Sender Address", '@') + 1));
        if IsGenericDomain(Domain) or (DelChr(Domain, '=', 'abcdefghijklmnopqrstuvwxyz0123456789.-') <> '') then
            exit(false);
        Vendor.SetFilter("E-Mail", '@*' + Domain + '*');
        if Vendor.FindSet() then
            repeat
                if StrPos(';' + DelChr(LowerCase(Vendor."E-Mail"), '=', ' ') + ';', '@' + Domain + ';') > 0 then
                    if Vendor."No." <> FoundVendorNo then begin
                        MatchCount += 1;
                        FoundVendorNo := Vendor."No.";
                    end;
            until (Vendor.Next() = 0) or (MatchCount > 1);
        case MatchCount of
            0:
                exit(false);
            1:
                exit(SetVendor(DNDocument, FoundVendorNo, MethodDomainLbl));
            else begin
                SetVendorAmbiguous(DNDocument, MethodDomainLbl);
                exit(false);
            end;
        end;
    end;

    local procedure TryVendorByName(var DNDocument: Record "IKA DN Document"): Boolean
    var
        Vendor: Record Vendor;
        SearchName: Text;
    begin
        SearchName := MakeSearchPattern(DNDocument."Ext. Vendor Name");
        if StrLen(DelChr(SearchName, '=', '?')) < 3 then
            exit(false);
        Vendor.SetFilter(Name, '@*' + SearchName + '*');
        if MatchSingleVendor(DNDocument, Vendor, MethodNameLbl) then
            exit(true);
        if DNDocument."Vendor Match Status" = DNDocument."Vendor Match Status"::Ambiguous then
            exit(false);
        Vendor.Reset();
        Vendor.SetFilter("Search Name", '@*' + SearchName + '*');
        exit(MatchSingleVendor(DNDocument, Vendor, MethodNameLbl));
    end;

    local procedure MatchSingleVendor(var DNDocument: Record "IKA DN Document"; var Vendor: Record Vendor; Method: Text): Boolean
    begin
        case Vendor.Count() of
            0:
                exit(false);
            1:
                begin
                    Vendor.FindFirst();
                    exit(SetVendor(DNDocument, Vendor."No.", Method));
                end;
            else begin
                SetVendorAmbiguous(DNDocument, Method);
                exit(false);
            end;
        end;
    end;

    local procedure SetVendorAmbiguous(var DNDocument: Record "IKA DN Document"; Method: Text)
    begin
        if DNDocument."Vendor Match Status" <> DNDocument."Vendor Match Status"::Ambiguous then
            DNDocument.AddReviewNote(StrSubstNo(VendorAmbiguousLbl, Method));
        DNDocument."Vendor Match Status" := DNDocument."Vendor Match Status"::Ambiguous;
    end;

    local procedure SetVendor(var DNDocument: Record "IKA DN Document"; VendorNo: Code[20]; Method: Text): Boolean
    var
        Vendor: Record Vendor;
    begin
        if not Vendor.Get(VendorNo) then
            exit(false);
        DNDocument."Vendor No." := Vendor."No.";
        DNDocument."Vendor Match Status" := DNDocument."Vendor Match Status"::Matched;
        DNDocument."Vendor Match Method" := CopyStr(Method, 1, MaxStrLen(DNDocument."Vendor Match Method"));
        CheckVendorBlocked(DNDocument);
        exit(true);
    end;

    local procedure CheckVendorBlocked(var DNDocument: Record "IKA DN Document")
    var
        Vendor: Record Vendor;
    begin
        if Vendor.Get(DNDocument."Vendor No.") then
            if Vendor.Blocked <> Vendor.Blocked::" " then
                DNDocument.AddReviewNote(StrSubstNo(VendorBlockedLbl, Vendor."No."));
    end;

    local procedure IsGenericDomain(Domain: Text): Boolean
    begin
        exit(Domain in ['gmail.com', 'hotmail.com', 'hotmail.es', 'outlook.com', 'outlook.es', 'live.com', 'yahoo.com', 'yahoo.es', 'icloud.com', 'telefonica.net', 'movistar.es', 'euskaltel.net', '']);
    end;

    // ---------------- Producto ----------------

    /// <summary>
    /// Busca el producto de la línea. Requiere el proveedor ya resuelto para las búsquedas
    /// por referencia de proveedor y por pedidos abiertos.
    /// </summary>
    procedure ResolveItem(DNDocument: Record "IKA DN Document"; var DocumentLine: Record "IKA DN Document Line"; AllowDescriptionMatch: Boolean)
    begin
        if (DocumentLine."Item Match Status" = DocumentLine."Item Match Status"::Manual) and (DocumentLine."Item No." <> '') then
            exit;

        DocumentLine."Item No." := '';
        DocumentLine."Variant Code" := '';
        DocumentLine."Unit of Measure Code" := '';
        DocumentLine."Item Match Method" := '';
        DocumentLine."Item Match Status" := DocumentLine."Item Match Status"::"Not Found";

        if TryVendorReference(DNDocument, DocumentLine) then
            exit;
        if TryItemVendorCatalog(DNDocument, DocumentLine) then
            exit;
        if TryItemCardVendorItemNo(DNDocument, DocumentLine) then
            exit;
        if TryItemNo(DocumentLine, DocumentLine."Ext. Our Item Code") then
            exit;
        if TryBarCode(DocumentLine, DocumentLine."Ext. EAN") then
            exit;
        if TryOpenOrderVendorItemNo(DNDocument, DocumentLine) then
            exit;
        if TryBarCode(DocumentLine, DocumentLine."Ext. Vendor Item Code") then
            exit;
        if TryItemNo(DocumentLine, DocumentLine."Ext. Vendor Item Code") then
            exit;
        if AllowDescriptionMatch then begin
            if TryOpenOrderDescription(DNDocument, DocumentLine) then
                exit;
            if TryItemDescription(DocumentLine) then
                exit;
        end;
        if DocumentLine."Item Match Status" = DocumentLine."Item Match Status"::"Not Found" then
            DocumentLine."Discrepancy Text" := ItemNotFoundLbl;
    end;

    local procedure TryVendorReference(DNDocument: Record "IKA DN Document"; var DocumentLine: Record "IKA DN Document Line"): Boolean
    var
        ItemReference: Record "Item Reference";
    begin
        if (DNDocument."Vendor No." = '') or (DocumentLine."Ext. Vendor Item Code" = '') then
            exit(false);
        ItemReference.SetRange("Reference Type", ItemReference."Reference Type"::Vendor);
        ItemReference.SetRange("Reference Type No.", DNDocument."Vendor No.");
        ItemReference.SetRange("Reference No.", CopyStr(UpperCase(DocumentLine."Ext. Vendor Item Code"), 1, MaxStrLen(ItemReference."Reference No.")));
        exit(MatchSingleReference(DocumentLine, ItemReference, MethodVendorRefLbl));
    end;

    local procedure TryBarCode(var DocumentLine: Record "IKA DN Document Line"; Code: Text): Boolean
    var
        ItemReference: Record "Item Reference";
    begin
        if (StrLen(Code) < 8) or (DelChr(Code, '=', '0123456789') <> '') then
            exit(false);
        ItemReference.SetRange("Reference Type", ItemReference."Reference Type"::"Bar Code");
        ItemReference.SetRange("Reference No.", CopyStr(Code, 1, MaxStrLen(ItemReference."Reference No.")));
        exit(MatchSingleReference(DocumentLine, ItemReference, MethodEanLbl));
    end;

    local procedure MatchSingleReference(var DocumentLine: Record "IKA DN Document Line"; var ItemReference: Record "Item Reference"; Method: Text): Boolean
    begin
        case ItemReference.Count() of
            0:
                exit(false);
            1:
                begin
                    ItemReference.FindFirst();
                    SetItem(DocumentLine, ItemReference."Item No.", ItemReference."Variant Code", ItemReference."Unit of Measure", Method);
                    exit(true);
                end;
            else begin
                SetItemAmbiguous(DocumentLine, Method);
                exit(false);
            end;
        end;
    end;

    local procedure TryItemVendorCatalog(DNDocument: Record "IKA DN Document"; var DocumentLine: Record "IKA DN Document Line"): Boolean
    var
        ItemVendor: Record "Item Vendor";
    begin
        if (DNDocument."Vendor No." = '') or (DocumentLine."Ext. Vendor Item Code" = '') then
            exit(false);
        ItemVendor.SetRange("Vendor No.", DNDocument."Vendor No.");
        ItemVendor.SetRange("Vendor Item No.", CopyStr(DocumentLine."Ext. Vendor Item Code", 1, MaxStrLen(ItemVendor."Vendor Item No.")));
        case ItemVendor.Count() of
            0:
                exit(false);
            1:
                begin
                    ItemVendor.FindFirst();
                    SetItem(DocumentLine, ItemVendor."Item No.", ItemVendor."Variant Code", '', MethodItemVendorLbl);
                    exit(true);
                end;
            else begin
                SetItemAmbiguous(DocumentLine, MethodItemVendorLbl);
                exit(false);
            end;
        end;
    end;

    local procedure TryItemCardVendorItemNo(DNDocument: Record "IKA DN Document"; var DocumentLine: Record "IKA DN Document Line"): Boolean
    var
        Item: Record Item;
    begin
        if (DNDocument."Vendor No." = '') or (DocumentLine."Ext. Vendor Item Code" = '') then
            exit(false);
        Item.SetRange("Vendor No.", DNDocument."Vendor No.");
        Item.SetRange("Vendor Item No.", CopyStr(DocumentLine."Ext. Vendor Item Code", 1, MaxStrLen(Item."Vendor Item No.")));
        case Item.Count() of
            0:
                exit(false);
            1:
                begin
                    Item.FindFirst();
                    SetItem(DocumentLine, Item."No.", '', '', MethodItemVendorNoLbl);
                    exit(true);
                end;
            else begin
                SetItemAmbiguous(DocumentLine, MethodItemVendorNoLbl);
                exit(false);
            end;
        end;
    end;

    local procedure TryItemNo(var DocumentLine: Record "IKA DN Document Line"; Code: Text): Boolean
    var
        Item: Record Item;
    begin
        if (Code = '') or (StrLen(Code) > MaxStrLen(Item."No.")) then
            exit(false);
        if not Item.Get(UpperCase(Code)) then
            exit(false);
        SetItem(DocumentLine, Item."No.", '', '', MethodItemNoLbl);
        exit(true);
    end;

    local procedure TryOpenOrderVendorItemNo(DNDocument: Record "IKA DN Document"; var DocumentLine: Record "IKA DN Document Line"): Boolean
    var
        PurchaseLine: Record "Purchase Line";
    begin
        if (DNDocument."Vendor No." = '') or (DocumentLine."Ext. Vendor Item Code" = '') then
            exit(false);
        FilterOpenOrderLines(PurchaseLine, DNDocument."Vendor No.");
        PurchaseLine.SetRange("Vendor Item No.", CopyStr(DocumentLine."Ext. Vendor Item Code", 1, MaxStrLen(PurchaseLine."Vendor Item No.")));
        exit(MatchSingleItemInPurchLines(DocumentLine, PurchaseLine, MethodOpenOrderLbl));
    end;

    local procedure TryOpenOrderDescription(DNDocument: Record "IKA DN Document"; var DocumentLine: Record "IKA DN Document Line"): Boolean
    var
        PurchaseLine: Record "Purchase Line";
        SearchText: Text;
    begin
        SearchText := MakeSearchPattern(CopyStr(DocumentLine."Ext. Description", 1, 100));
        if (DNDocument."Vendor No." = '') or (StrLen(DelChr(SearchText, '=', '?')) < 4) then
            exit(false);
        FilterOpenOrderLines(PurchaseLine, DNDocument."Vendor No.");
        PurchaseLine.SetFilter(Description, '@*' + SearchText + '*');
        exit(MatchSingleItemInPurchLines(DocumentLine, PurchaseLine, MethodDescriptionOrderLbl));
    end;

    /// <summary>
    /// Coincide si todas las líneas de pedido filtradas son del mismo producto.
    /// </summary>
    local procedure MatchSingleItemInPurchLines(var DocumentLine: Record "IKA DN Document Line"; var PurchaseLine: Record "Purchase Line"; Method: Text): Boolean
    var
        FoundItemNo: Code[20];
        FoundVariant: Code[10];
    begin
        if not PurchaseLine.FindSet() then
            exit(false);
        FoundItemNo := PurchaseLine."No.";
        FoundVariant := PurchaseLine."Variant Code";
        repeat
            if (PurchaseLine."No." <> FoundItemNo) or (PurchaseLine."Variant Code" <> FoundVariant) then begin
                SetItemAmbiguous(DocumentLine, Method);
                exit(false);
            end;
        until PurchaseLine.Next() = 0;
        SetItem(DocumentLine, FoundItemNo, FoundVariant, '', Method);
        exit(true);
    end;

    local procedure TryItemDescription(var DocumentLine: Record "IKA DN Document Line"): Boolean
    var
        Item: Record Item;
        SearchText: Text;
    begin
        SearchText := MakeSearchPattern(CopyStr(DocumentLine."Ext. Description", 1, 100));
        if StrLen(DelChr(SearchText, '=', '?')) < 4 then
            exit(false);
        Item.SetRange(Blocked, false);
        Item.SetFilter(Description, '@*' + SearchText + '*');
        if Item.Count() = 0 then begin
            Item.SetRange(Description);
            Item.SetFilter("Search Description", '@*' + SearchText + '*');
        end;
        case Item.Count() of
            0:
                exit(false);
            1:
                begin
                    Item.FindFirst();
                    SetItem(DocumentLine, Item."No.", '', '', MethodDescriptionLbl);
                    exit(true);
                end;
            else begin
                SetItemAmbiguous(DocumentLine, MethodDescriptionLbl);
                exit(false);
            end;
        end;
    end;

    local procedure SetItem(var DocumentLine: Record "IKA DN Document Line"; ItemNo: Code[20]; VariantCode: Code[10]; UoMCode: Code[10]; Method: Text)
    begin
        DocumentLine."Item No." := ItemNo;
        DocumentLine."Variant Code" := VariantCode;
        DocumentLine."Unit of Measure Code" := UoMCode;
        DocumentLine."Item Match Status" := DocumentLine."Item Match Status"::Matched;
        DocumentLine."Item Match Method" := CopyStr(Method, 1, MaxStrLen(DocumentLine."Item Match Method"));
        DocumentLine."Discrepancy Text" := '';
        if DocumentLine."Unit of Measure Code" = '' then
            ResolveUnitOfMeasure(DocumentLine);
    end;

    local procedure SetItemAmbiguous(var DocumentLine: Record "IKA DN Document Line"; Method: Text)
    begin
        DocumentLine."Item Match Status" := DocumentLine."Item Match Status"::Ambiguous;
        DocumentLine."Discrepancy Text" := CopyStr(StrSubstNo(ItemAmbiguousLbl, Method), 1, MaxStrLen(DocumentLine."Discrepancy Text"));
    end;

    procedure ResolveUnitOfMeasure(var DocumentLine: Record "IKA DN Document Line")
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        UnitOfMeasure: Record "Unit of Measure";
        UoMText: Text;
    begin
        if (DocumentLine."Item No." = '') or (DocumentLine."Ext. Unit of Measure" = '') then
            exit;
        UoMText := UpperCase(DelChr(DocumentLine."Ext. Unit of Measure", '<>', ' .'));
        if StrLen(UoMText) <= MaxStrLen(ItemUnitOfMeasure.Code) then
            if ItemUnitOfMeasure.Get(DocumentLine."Item No.", UoMText) then begin
                DocumentLine."Unit of Measure Code" := ItemUnitOfMeasure.Code;
                exit;
            end;
        UnitOfMeasure.SetFilter(Description, '@' + MakeSearchPattern(UoMText) + '*');
        if UnitOfMeasure.FindSet() then
            repeat
                if ItemUnitOfMeasure.Get(DocumentLine."Item No.", UnitOfMeasure.Code) then begin
                    DocumentLine."Unit of Measure Code" := ItemUnitOfMeasure.Code;
                    exit;
                end;
            until UnitOfMeasure.Next() = 0;
        // Si no se reconoce, se asumirá la unidad de la línea del pedido
    end;

    procedure FilterOpenOrderLines(var PurchaseLine: Record "Purchase Line"; VendorNo: Code[20])
    begin
        PurchaseLine.Reset();
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Buy-from Vendor No.", VendorNo);
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetFilter("Outstanding Quantity", '>0');
    end;

    /// <summary>
    /// Sustituye por "?" los caracteres con significado en los filtros de BC.
    /// </summary>
    procedure MakeSearchPattern(Value: Text): Text
    var
        Result: Text;
        i: Integer;
        Ch: Text[1];
    begin
        Value := DelChr(Value, '<>', ' ');
        for i := 1 to StrLen(Value) do begin
            Ch := CopyStr(Value, i, 1);
            if Ch in ['&', '|', '(', ')', '<', '>', '=', '*', '@', '''', '"', '.', '%'] then
                Result += '?'
            else
                Result += Ch;
        end;
        exit(Result);
    end;
}
