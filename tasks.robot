*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.FileSystem
Library             RPA.Archive
Library             RPA.RobotLogListener


*** Variables ***
${OUTPUT_DIR}=      output


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    Download the orders file
    Fill the forms and export receipt
    Archive Folder With Zip    ${OUTPUT_DIR}${/}    ${OUTPUT_DIR}${/}receipts.zip    recursive=True
    [Teardown]    Close Browser


*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Download the orders file
    Download
    ...    https://robotsparebinindustries.com/orders.csv
    ...    overwrite=True

Fill the forms and export receipt
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        TRY
            Fill the form    ${row}
            Wait Until Element Is Visible    receipt    timeout=10
        EXCEPT
            TRY
                Sleep    500ms
                Wait Until Keyword Succeeds    10x    6sec
                ...    Fill the form    ${row}
                Wait Until Element Is Visible    receipt
            EXCEPT
                Log    2nd Try After Error
                Open the robot order website
                CONTINUE
            END
        END
        Download and Store Receipt    ${row}
        Order another robot
    END

Get orders
    ${table}=    Read table from CSV    orders.csv
    RETURN    ${table}

Close the annoying modal
    Click Button    css:.alert-buttons > button:nth-child(1)

Fill the form
    [Arguments]    ${row}
    Select From List By Value    head    ${row}[Head]
    Select Radio Button    body    ${row}[Body]
    Input Text    css:input[type="number"]    ${row}[Legs]
    Input Text    address    ${row}[Address]
    Click Button    id:preview
    Click Button    id:order

Store the receipt as a PDF file
    [Arguments]    ${row_order_number}
    ${sales_results_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${sales_results_html}    ${OUTPUT_DIR}${/}${row_order_number}.pdf
    RETURN    ${OUTPUT_DIR}${/}${row_order_number}.pdf

Take a screenshot of the robot
    [Arguments]    ${row_order_number}
    Screenshot    css:div[id="robot-preview-image"]    ${OUTPUT_DIR}${/}${row_order_number}.png
    RETURN    ${OUTPUT_DIR}${/}${row_order_number}.png

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    Wait Until Created    ${screenshot}
    Wait Until Created    ${pdf}
    Open Pdf    ${pdf}
    Add Watermark Image To PDF
    ...    image_path=${screenshot}
    ...    source_path=${pdf}
    ...    output_path=${pdf}
    ...    coverage=0.2
    Close Pdf
    Remove File    ${screenshot}

Download and Store Receipt
    [Arguments]    ${row}
    ${pdf}=    Store the receipt as a PDF File    ${row}[Order number]
    ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
    Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}

Order another robot
    Click Button    id:order-another
