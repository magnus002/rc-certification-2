*** Settings ***
Documentation       Downloading the orders, filing them, and documenting the receipts.

Library             RPA.Browser.Selenium    auto_close=${False}
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.Desktop
Library             Collections
Library             RPA.Archive
Library             DateTime
Library             OperatingSystem
Library             RPA.FileSystem


*** Variables ***
@{MODEL_LIST}           @{EMPTY}
@{FILES_TO_ARCHIVE}     @{EMPTY}
${TABLE}                @{EMPTY}


*** Tasks ***
Downloading the orders, filing them, and documenting the receipts
    ${TABLE}=    Get orders and initialize
    Close the popup
    FOR    ${row}    IN    @{TABLE}
        Close the popup
        Fill each order    ${row}    ${MODEL_LIST}
        Document each order    ${row}
    END
    Create a ZIP archive    ${FILES_TO_ARCHIVE}
    Remove temp files
    [Teardown]    Close the Browser


*** Keywords ***
Get orders and initialize
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True

    ${output_dir_exist}=    Does Directory Exist    ${OUTPUT_DIR}${/}output
    IF    ${output_dir_exist} == False
        RPA.FileSystem.Create Directory    ${OUTPUT_DIR}${/}output
    END
    ${temp_dir_exist}=    Does Directory Exist    ${OUTPUT_DIR}${/}temp${/}
    IF    ${temp_dir_exist} == False
        RPA.FileSystem.Create Directory    ${OUTPUT_DIR}${/}temp${/}
    END
    ${temp_order_dir_exist}=    Does Directory Exist    ${OUTPUT_DIR}${/}temp${/}order${/}
    IF    ${temp_order_dir_exist} == False
        RPA.FileSystem.Create Directory    ${OUTPUT_DIR}${/}temp${/}order${/}
    END

    ${TABLE}=    Read table from CSV    orders.csv
    Log    Table content: ${table}
    RETURN    ${TABLE}

Close the popup
    ${is_ok_visible}=    Run Keyword    Is Element Visible    class:alert-buttons
    IF    ${is_ok_visible}    Click Button    OK

Click Button Order Until Not Visible
    ${is_element_visible}=    Run Keyword And Return Status    Element Should Be Visible    id:order-completion
    FOR    ${i}    IN RANGE    1    20
        ${is_element_visible}=    Run Keyword And Return Status    Element Should Be Visible    id:order-completion
        IF    ${is_element_visible}    BREAK
        Click Button    Order
        Sleep    500ms
    END

# -----PROCESS-----

Fill each order
    [Arguments]    ${row}    ${MODEL_LIST}
    ${counter}=    Set Variable    1
    Select From List By Value    head    ${row}[Head]
    Click Button    id-body-${row}[Body]
    Input Text    //*[@placeholder="Enter the part number for the legs"]    ${row}[Legs]
    Input Text    address    ${row}[Address]
    ${counter}=    Evaluate    ${counter}+1

Document each order
    [Arguments]    ${row}
    Click Button    Preview
    Wait Until Element Is Visible    id:robot-preview-image
    Click Button Order Until Not Visible

    ${receipt_html}=    Get Element Attribute    id:order-completion    outerHTML
    ${output_receipt}=    Set Variable    ${OUTPUT_DIR}${/}temp${/}receipt ${row}[Order number].pdf
    ${output_preview}=    Set Variable    ${OUTPUT_DIR}${/}temp${/}preview img ${row}[Order number].png
    ${output_order}=    Set Variable    ${OUTPUT_DIR}${/}temp${/}order${/}order ${row}[Order number].pdf

    Html To Pdf    ${receipt_html}    ${output_receipt}
    Screenshot    id:robot-preview-image    ${output_preview}

    ${files}=    Create List
    ...    ${output_receipt}
    ...    ${output_preview}
    Add Files To Pdf    ${files}    ${output_order}
    Append To List    ${FILES_TO_ARCHIVE}    ${output_order}
    Click Button    Order another robot

Create a ZIP archive
    [Arguments]    ${FILES_TO_ARCHIVE}
    ${date_time}=    Get Current Date
    ...    result_format=%Y%m%d-%H%M%S

    ${order_dir}=    Set Variable    ${OUTPUT_DIR}${/}temp${/}order${/}
    Archive Folder With ZIP    ${order_dir}    orders.zip    recursive=True    exclude=/.*

    File Should Exist    ${OUTPUT_DIR}${/}orders.zip
    OperatingSystem.Move File    ${OUTPUT_DIR}${/}orders.zip    ${OUTPUT_DIR}${/}output

Close the Browser
    Close Browser

Remove temp files
    ${files_in_temp}=    OperatingSystem.List Files In Directory    ${OUTPUT_DIR}${/}temp${/}
    ${files_in_order}=    OperatingSystem.List Files In Directory    ${OUTPUT_DIR}${/}temp${/}order

    FOR    ${file}    IN    @{FILES_IN_TEMP}
        OperatingSystem.Remove File    ${OUTPUT_DIR}${/}temp${/}${file}
    END
    FOR    ${file}    IN    @{FILES_IN_ORDER}
        OperatingSystem.Remove File    ${OUTPUT_DIR}${/}temp${/}order${/}${file}
    END
