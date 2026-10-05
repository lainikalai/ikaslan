pageextension 50403 "IKA Mail Bank Account Card" extends "Bank Account Card"
{
    layout
    {
        addfirst(factboxes)
        {
            part("IKA Mail Linked Emails"; "IKA Mail Linked Emails")
            {
                ApplicationArea = All;
                SubPageLink = "Entity Type" = const("Bank Account"), "Entity No." = field("No.");
            }
            // Esta ficha no trae el FactBox de adjuntos estándar en todas las versiones.
            // Si al compilar o en pantalla aparece duplicado, borre esta parte.
            part("IKA Attached Documents"; "Doc. Attachment List Factbox")
            {
                ApplicationArea = All;
                Caption = 'Documentos adjuntos';
                SubPageLink = "Table ID" = const(270), "No." = field("No.");
            }
        }
    }
}
