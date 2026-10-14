pageextension 99351 "IKA WA Order Processor RC" extends "Order Processor Role Center"
{
    layout
    {
        addfirst(rolecenter)
        {
            part("IKA WA Activities"; "IKA WA Activities")
            {
                ApplicationArea = All;
            }
        }
    }
}
