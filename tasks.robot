*** Settings ***
#Author: BRG (Ganesh B Ramakrishnan)
Library           RPA.Browser.Selenium
Library           RPA.HTTP
Library           RPA.Tables
Library           RPA.PDF
Library           RPA.RobotLogListener
Library           RPA.FileSystem
Library           Collections
Library           RPA.Robocloud.Secrets
Library           RPA.Archive
Library           RPA.Dialogs


*** Variables ***
@{MODEL_INFO}=    0    
${MAX_ATTEMPTS}=    5


*** Keywords ***
Download CSV
    ${urls}=    Get Secret    urls
    Download    ${urls}[csv_url]    overwrite=True

*** Keywords ***
Proceed to Automate
    ${proceed}    Set Variable   False
    Add icon      Success
    Add heading   Ready to order 20 Robots,By Confirming you are entering into the Automation Economy(Only Yes allowed, To Verify you are Human)?
    Add submit buttons    buttons=Yes,YES    default=Yes
    ${result}=    Run dialog
    IF   $result.submit == "Yes"
        ${proceed}    Set Variable    True
    END
    [return]    ${proceed}



*** Keywords ***
Open the robot ordering website
    ${urls}=    Get Secret    urls
    Open Available Browser     ${urls}[order_url]


*** Keywords ***
Get orders
    Download CSV
    ${orders}=    Read table from CSV    orders.csv
    Log    Found columns: ${orders.columns}
    [return]    ${orders}

*** Keywords ***
Close dialog
    ${found}=     Run keyword And Return Status    Wait Until Page Contains Element    class:modal-content    timeout=3    error=false
    IF    ${found}
        Log    Found Modal!
        Click Button    OK
    END

*** Keywords ***
Fill form
    [Arguments]    ${row}
    # Log    OrdNum> ${row}[Order number] Head> ${MODEL_INFO}[${row}[Head]] Body> ${MODEL_INFO}[${row}[Body]] Legs> ${MODEL_INFO}[${row}[Legs]]
    Select From List By Value        id:head             ${row}[Head]
    #Select Radio Button              body                ${MODEL_INFO}[${row}[Body]] body
    Click Button                     id:id-body-${row}[Body]
    Input Text                       xpath://html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${row}[Legs]
    Input Text                       id:address          ${row}[Address]


*** Keywords ***
Preview the robot
    Click Button                     id:preview
    FOR    ${i}    IN RANGE    ${MAX_ATTEMPTS}
        ${found}=     Run keyword And Return Status    Wait Until Element Is Visible    id:robot-preview-image
        IF     ${found} == True
            Exit For Loop If    True
        ELSE
            Click Button                     id:preview
            Sleep    1
        END
    END

*** Keywords ***
Place order
    Click Button                     id:order
    FOR    ${i}    IN RANGE    ${MAX_ATTEMPTS}
        ${found}=     Run keyword And Return Status    Wait Until Element Is Visible    id:receipt
        IF     ${found} == True
            Exit For Loop If    True
        ELSE
            Click Button                     id:order
            Sleep    1
        END
    END 

*** Keywords ***
Save as PDF
    [Arguments]    ${order_num}
    ${sales_receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${sales_receipt_html}    ${CURDIR}${/}output${/}recipt_${order_num}.pdf
    [return]    ${CURDIR}${/}output${/}recipt_${order_num}.pdf


*** Keywords ***
Selfie of BOT
    [Arguments]    ${order_num}
    Screenshot    id:robot-preview-image    ${CURDIR}${/}output${/}rbt_view_${order_num}.png
    [return]    ${CURDIR}${/}output${/}rbt_view_${order_num}.png


*** Keywords ***
Add Selfie to respective receipt in PDF    
    [Arguments]    ${screenshot}    ${pdf}
    Add Watermark Image To PDF    image_path=${screenshot}    source_path=${pdf}    output_path=${pdf}    coverage=0.2


*** Keywords ***
Next BOT
    Click Button                     id:order-another

*** Keywords ***
Bundle of Receipt as ZIP
    Archive Folder With Zip  ${CURDIR}${/}output      ${CURDIR}${/}output${/}receipts.zip   include=*.pdf


*** Keywords ***
Close Entire Browser Session
    Close Browser

*** Tasks ***
Order BOTs from Industry
    ${proceed}=    Proceed to Automate
    IF    ${proceed}
        ${orders}=    Get orders
        Open the robot ordering website
        FOR    ${row}    IN    @{orders}
             Close dialog
             Fill form    ${row}
             Preview the robot
             Place order
             ${pdf}=    Save as PDF    ${row}[Order number]
             ${screenshot}=    Selfie of BOT    ${row}[Order number]
             Add Selfie to respective receipt in PDF    ${screenshot}    ${pdf}
             Next BOT
        END
        Bundle of Receipt as ZIP
    END
    [Teardown]    Close Entire Browser Session